import time
import threading
from fixture import DmxFixture
from universe import Universe
from sequence import Sequence

if __name__ == '__main__':
    sequenceOne = Sequence()
    sequenceOne.add_color(0, 0, 0, 0, 0)

    universeOne = Universe(1)

    fixtureOne = DmxFixture(1, sequenceOne)
    fixtureTwo = DmxFixture(9, sequenceOne)
    fixtureThree = DmxFixture(17, sequenceOne)
    fixtureFour = DmxFixture(25, sequenceOne)

    universeOne.add_fixture(fixtureOne)
    universeOne.add_fixture(fixtureTwo)
    universeOne.add_fixture(fixtureThree)
    universeOne.add_fixture(fixtureFour)

    universeOne.start()

    time.sleep(1)