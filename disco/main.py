import time
import threading
from fixture import DmxFixture
from universe import Universe
from sequence import Sequence

def bpm_input_listener(_universe):
    global bpm
    while True:
        try:
            user_input = input("Enter new BPM: ")
            _universe.set_BPM(int(user_input))
        except ValueError:
            print("Invalid BPM. Please enter a number.")


if __name__ == '__main__':
    sequenceOne = Sequence()
    sequenceOne.add_color(10, 0, 255,   0,   0  )
    sequenceOne.add_color(0, 0,   255,   0,   0)
    sequenceOne.add_color(0, 0, 255, 0,   0  )
    sequenceOne.add_color(0, 0,   255,   0,   0)
    sequenceOne.add_color(0, 0,   255, 0,   0  )
    sequenceOne.add_color(0, 0,   0,   0,   255)

    universeOne = Universe(1)

    fixtureOne = DmxFixture(1, sequenceOne, None,  0)
    fixtureTwo = DmxFixture(9, sequenceOne, None,  1)
    fixtureThree = DmxFixture(17, sequenceOne, None, 2)
    fixtureFour = DmxFixture(25, sequenceOne, None, 3)

    universeOne.add_fixture(fixtureOne)
    universeOne.add_fixture(fixtureTwo)
    universeOne.add_fixture(fixtureThree)
    universeOne.add_fixture(fixtureFour)

    universeOne.start()

    threading.Thread(target=bpm_input_listener, args=(universeOne,), daemon=True).start()
    while True:
        time.sleep(1)
