'''

import asyncio
import time

async def tcp_echo_client(message):
	# Connect to Welsh
	reader, writer = await asyncio.open_connection('127.0.0.1', 11765)
	# Connect to Holiday
	# reader, writer = await asyncio.open_connection('127.0.0.1', 11999, loop=loop)
	print("Sending:", message, end="")
	writer.write(message.encode())
	data = await reader.read(100000)
	print("Received:", data.decode(), end="")
	writer.close()

def main():
	# message = "\t\t\t\t\t    \f\f\fIAMAT\v\v\v\v\v   \t\fkiwi.cs.ucla.edu -33.86705222+151.1957 {0}\f\r\f\f\t\t\r\n".format(time.time())
	# message = "IAMAT kiwi.cs.ucla.edu -32.12+152.2 {0}\n".format(time.time())
	# message = "IAMAT other +34.0698-118.445127 {0}\n".format(time.time())
	# message = "WHATSAT kiwi.cs.ucla.edu 20 10\n"
	# message = "WHATSAT other 5 20\n"
	# message = "CHANGELOC kiwi.cs.ucla.edu -32.12+152.2 {0} {1} Holiday\n".format(time.time(), 2)
	# loop = asyncio.get_event_loop()
	asyncio.run(tcp_echo_client(message))
	# loop.close()

if __name__ == '__main__':
	main()

'''

"""
Note that this piece of code is (of course) only a hint
you are not required to use it
neither do you have to use any of the methods mentioned here
The code comes from
https://asyncio.readthedocs.io/en/latest/tcp_echo.html

To run:
1. start the echo_server.py first in a terminal
2. start the echo_client.py in another terminal
3. follow print-back instructions on client side until you quit
"""

import asyncio


class Client:
    def __init__(self, ip='127.0.0.1', port=11765, name='client', message_max_length=1e6):
        """
        127.0.0.1 is the localhost
        port could be any port
        """
        self.ip = ip
        self.port = port
        self.name = name
        self.message_max_length = int(message_max_length)

    async def tcp_echo_client(self, message):
        """
        on client side send the message for echo
        """
        reader, writer = await asyncio.open_connection(self.ip, self.port)
        print(f'{self.name} send: {message!r}')
        writer.write(message.encode())

        data = await reader.read(self.message_max_length)
        print(f'{self.name} received: {data.decode()!r}')
        print(f'{self.name} Interpreted: {data.decode()}')

        print('close the socket')
        # The following lines closes the stream properly
        # If there is any warning, it's due to a bug o Python 3.8: https://bugs.python.org/issue38529
        # Please ignore it
        writer.close()

    def run_until_quit(self):
        # start the loop
        while True:
            # collect the message to send
            message = input("Please input the next message to send: ")
            if message in ['quit', 'exit', ':q', 'exit;', 'quit;', 'exit()', '(exit)']:
                break
            else:
                asyncio.run(self.tcp_echo_client(message))


if __name__ == '__main__':
    client = Client()  # using the default settings
    client.run_until_quit()


