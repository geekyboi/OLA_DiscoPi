class Sequence:
    def __init__(self, _name=""):
        self.color_sequence = []
        self.movement_sequence = []
        self.name = _name
        self.color_length = 0
        self.movement_length = 0

    def add_color(self, _brightness=0, _red=0, _green=0, _blue=0, _white=0, _uv=0):
        self.color_length += 1
        self.color_sequence.append({'brightness': self.constrain(_brightness, 0, 255),
                              'red': self.constrain(_red, 0, 255),
                              'green': self.constrain(_green, 0, 255),
                              'blue':self.constrain(_blue, 0, 255),
                              'white':self.constrain(_white, 0, 255),
                              'uv':self.constrain(_uv, 0, 255)})

    def add_movement(self, _x=0, _y=0, _rot=0, _gobo=0):
        self.movement_length += 1
        self.movement_sequence.append({'x': self.constrain(_x, 0, 255),
                                       'y': self.constrain(_y, 0, 255),
                                       'rot': self.constrain(_rot, 0, 255),
                                       'gobo':self.constrain(_gobo, 0, 255)})

    def get_color_sequence(self):
        return self.color_sequence

    def get_color_length(self):
        return self.color_length

    def get_movement_sequence(self):
        return self.movement_sequence

    def get_movement_length(self):
        return self.movement_length

    @staticmethod
    def constrain(n, n_min, n_max):
        return max(min(n_max, n), n_min)
