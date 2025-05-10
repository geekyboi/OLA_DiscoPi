from ola.ClientWrapper import ClientWrapper
import array
import time
import threading

wrapper = None
bpm = 120

def bpm_input_listener():
    global bpm
    while True:
        try:
            user_input = input("Enter new BPM: ")
            bpm = int(user_input)
            print(f"BPM updated to {bpm}")
        except ValueError:
            print("Invalid BPM. Please enter a number.")

def setDMX(globalArray, data, address):
        x = 0
        for i in data:
                globalArray[address+x] = i
                x = x + 1
        return globalArray

def main():
        universe = 1
        global wrapper
        wrapper = ClientWrapper()
        client = wrapper.Client()
        multiplier = 1
        delay = 60/(bpm*multiplier)
        blankArray = [0]*512

        data = array.array('B', blankArray)

        data = setDMX(data, [255,0  ,0,255,0,0,0,0], 0)
        data = setDMX(data, [255,255,0,0  ,0,0,0,0], 7)
        data = setDMX(data, [255,255,0,0  ,0,0,0,0], 15)
        data = setDMX(data, [255,255,0,0  ,0,0,0,0], 23)
        client.SendDmx(universe, data)
        time.sleep(delay)

        data = setDMX(data, [255,255,0,0,0,0,0,0], 0)
        data = setDMX(data, [255,0  ,0,255,0,0,0,0], 7)
        data = setDMX(data, [255,255,0,0  ,0,0,0,0], 15)
        data = setDMX(data, [255,255,0,0  ,0,0,0,0], 23)
        client.SendDmx(universe, data)
        time.sleep(delay)

        data = setDMX(data, [255,255,0,0  ,0,0,0,0], 0)
        data = setDMX(data, [255,255,0,0  ,0,0,0,0], 7)
        data = setDMX(data, [255,0  ,0,255,0,0,0,0], 15)
        data = setDMX(data, [255,255,0,0  ,0,0,0,0], 23)
        client.SendDmx(universe, data)
        time.sleep(delay)

        data = setDMX(data, [255,255,0,0  ,0,0,0,0], 0)
        data = setDMX(data, [255,255,0,0  ,0,0,0,0], 7)
        data = setDMX(data, [255,255,0,0  ,0,0,0,0], 15)
        data = setDMX(data, [255,0  ,0,255,0,0,0,0], 23)
        client.SendDmx(universe, data)
        time.sleep(delay)

        data = setDMX(data, [255,0  ,255,0,0,0,0,0], 0)
        data = setDMX(data, [255,255,0,0  ,0,0,0,0], 7)
        data = setDMX(data, [255,255,0,0  ,0,0,0,0], 15)
        data = setDMX(data, [255,255,0,0  ,0,0,0,0], 23)
        client.SendDmx(universe, data)
        time.sleep(delay)

        data = setDMX(data, [255,255,0  ,0,0,0,0,0], 0)
        data = setDMX(data, [255,0  ,255,0,0,0,0,0], 7)
        data = setDMX(data, [255,255,0,0  ,0,0,0,0], 15)
        data = setDMX(data, [255,255,0,0  ,0,0,0,0], 23)
        client.SendDmx(universe, data)
        time.sleep(delay)

        data = setDMX(data, [255,255,0,0  ,0,0,0,0], 0)
        data = setDMX(data, [255,255,0,0  ,0,0,0,0], 7)
        data = setDMX(data, [255,0  ,255,0,0,0,0,0], 15)
        data = setDMX(data, [255,255,0,0  ,0,0,0,0], 23)
        client.SendDmx(universe, data)
        time.sleep(delay)

        data = setDMX(data, [255,255,0,0  ,0,0,0,0], 0)
        data = setDMX(data, [255,255,0,0  ,0,0,0,0], 7)
        data = setDMX(data, [255,255,0,0  ,0,0,0,0], 15)
        data = setDMX(data, [255,0  ,255,0,0,0,0,0], 23)
        client.SendDmx(universe, data)
        time.sleep(delay)

if __name__ == '__main__':
        threading.Thread(target=bpm_input_listener, daemon=True).start()
        while True:
                main()
