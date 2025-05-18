import time
import threading
import array
from ola.ClientWrapper import ClientWrapper

class Universe:
    def __init__(self, _universe):
        self.wrapper = ClientWrapper()
        self.client = self.wrapper.Client()
        self.universe = _universe
        self.size = 512
        self.dmx_data = array.array('B', [0] * self.size)
        self.dmx_lock = threading.Lock()
        self.now = 0
        self.now_lock = threading.Lock()
        self.fixture = []
        self.bpm = 60/120
        self.tick_thread = threading.Thread(target=self.sequence_tick, daemon=True)
        self.dmx_sender_thread = threading.Thread(target=self.dmx_sender, daemon=True)

    def add_fixture(self, _fixture):
        self.fixture.append(_fixture)

    def start(self):
        self.tick_thread.start()
        self.dmx_sender_thread.start()

    def set_BPM(self, _bpm):
        self.bpm = 60/_bpm

    def dmx_sender(self):
        while True:
            with self.dmx_lock:
                self.client.SendDmx(self.universe, self.dmx_data)
            time.sleep(0.01)

    def update_data(self, _data, _start_channel):
        with self.dmx_lock:
            x = 0
            for byte in _data:
                self.dmx_data[_start_channel+x] = self.constrain(byte)
                x += 1

    def sequence_tick(self):
        while True:
            with self.now_lock:
           	 self.now = time.monotonic()
           	 for seq in self.fixture:
               		 seq.update(self.now, self.bpm)
               		 self.update_data(seq.get_data(), seq.get_channel())
            time.sleep(0.005)

    @staticmethod
    def constrain(n):
        return max(min(255, n), 0)
