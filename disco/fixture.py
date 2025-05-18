import time

class DmxFixture:
    def __init__(self, _channel_start, _color_sequence, _movement_sequence=None, _group_position=0):
        self.channel_start = _channel_start - 1  # DMX values are 1-512
        self.size = 8
        self.data = [0]*self.size
        self.bpm = 0.5
        self.chain_position = 0
        self.color_sequence = _color_sequence
        self.color_previous_time = 0
        self.color_sequence_step = 0
        self.movement_sequence = _movement_sequence
        self.movement_previous_time = 0
        self.movement_sequence_step = 0
        self.group_position = _group_position

    def update(self, _now, _bpm):
        self.bpm = _bpm
        if self.color_sequence is not None:
            if _now - self.color_previous_time > self.bpm:
                self.color_previous_time = time.monotonic()
                color_data = self.color_sequence.get_color_sequence()[(self.color_sequence_step + self.group_position) % self.color_sequence.get_color_length()]
                self.data = [color_data['brightness'],
                             color_data['red'],
                             color_data['green'],
                             color_data['blue'],
                             color_data['white'],
                             0,0,0]
                self.color_sequence_step += 1

            if self.movement_sequence is not None:
                pass

    def get_data(self):
        return self.data

    def get_channel(self):
        return self.channel_start

    def get_size(self):
        return self.size

    def get_start_channel(self):
        return self.channel_start
