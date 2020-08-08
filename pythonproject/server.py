import asyncio
import time
import aiohttp
import sys
import json

global loop
global rec_server

API_KEY = 'AIzaSyAOjTmEJmx2gr3KE9WoSnN-4Nc4KImOdSY'

client = {}

server_tree = {
    'Hill': ['Jaquez', 'Smith'],
    'Jaquez': ['Singleton', 'Hill'],
    'Smith': ['Campbell', 'Singleton', 'Hill'],
    'Campbell': ['Smith', 'Singleton'],
    'Singleton': ['Jaquez', 'Smith', 'Campbell']
}

server_ports = {
    'Hill': 11765,
    'Jaquez': 11766,
    'Smith': 11767,
    'Campbell': 11768,
    'Singleton': 11769
}

# https://asyncio.readthedocs.io/en/latest/tcp_echo.html
async def handle_echo(reader, writer):
    data = await reader.read(1000000) 
    at_time = time.time()
    message = data.decode()
    server_logs.write("at %f , server received data:\n %s \n" % (at_time, message))
    response = await validation(message, at_time)
    if not isinstance(response, str):
        pass
    elif response[0] == '':
        pass
    elif response[0] != '?':
        server_logs.write("data processed, sending:\n %s\n" % response)
        writer.write(response.encode())
        await writer.drain()
    else:
        server_logs.write("unable to process data, sending:\n %s\n" % response)
        writer.write(response.encode())
        await writer.drain()

    writer.close()

async def flooding(message, typ):
    fld_msg = ""
    if typ == 0:
        fld_msg = "FLOODING "+message+","+sname
    elif typ == 1:
        fld_msg = message+" "+sname

    for connec in server_tree[sname]:
        server_logs.write("flooding to server %s\n" % connec)
        try:
            reader, writer = await asyncio.open_connection('127.0.0.1', server_ports[connec])
            writer.write(fld_msg.encode())
            await writer.drain()
            writer.close()
            server_logs.write("flooding success.\n")
        except:
            server_logs.write("flooding failure.\n")


def handle_err(message):
    return "? "+ message

def get_loc(addr):
    if len(addr) < 4:
        return ""
    else:
        for i in range(1, len(addr)):
            if addr[i] == '+' or addr[i] == '-':
                return addr[:i]+","+addr[i:]
            i += 1
    return ""

async def handle_whatsat(message,at_time):
    msg_list = message.split()
    msg_type = msg_list[0]
    msg_id = msg_list[1]
    msg_rad = msg_list[2]
    msg_bound = msg_list[3]
    if len(msg_list) != 4:
        server_logs.write("Failure: whatsat not in correct format\n")
        return handle_err(message)  
    else: 
        try:
            int_rad = float(msg_rad)
            int_bound = int(msg_bound)
            client_addr = client[msg_id].split()[4]
            api_loc = get_loc(client_addr)
            if api_loc == "":
                raise ValueError('empty string')
        except:
            server_logs.write("Failure: whatsat contains inproper data\n")
            return handle_err(message)
        google_url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=%s&radius=%s&key=%s' % (api_loc,msg_rad,API_KEY)
        async with aiohttp.ClientSession() as gethttp:
            async with gethttp.get(google_url) as json_get:
                json_res = await json_get.json()
                json_res['results'] = json_res['results'][:int_bound]
                json_str = json.dumps(json_res, indent=4)+"\n\n"
        ret_msg = client[msg_id]+"\n"+json_str
        return ret_msg

async def handle_iamat(message, at_time):
    msg_list = message.split()
    if len(msg_list) != 4:
        server_logs.write("Failure: iamat not in correct format\n")
        return handle_err(message)  
    else:
        msg_type = msg_list[0]
        msg_id = msg_list[1]
        msg_loc = msg_list[2]
        msg_time = msg_list[3]
        try:
            client_time = float(msg_time)
        except:
            server_logs.write("Failure: iamat contains inproper data\n")
            return handle_err(message)
        diff_time = "%+f" % (at_time - client_time)
        ret_msg = "AT "+sname+" "+diff_time+" "+message.split(None, 1)[1]
        client[msg_id] = ret_msg
        await flooding(ret_msg,0)
        return ret_msg

async def handle_flooding(message):
    msg_pair = message.split(',')
    who_knows = msg_pair[1].split()
    client_id = msg_pair[0].split()[4]
    client_info = msg_pair[0].split(' ', 1)[1]
    if sname not in who_knows:
        client[client_id] = client_info
        server_logs.write("Update client data, %s : %s\n" % (client_id, client[client_id]))
        await flooding(message, 1)

async def validation(message, at_time):
    msg_list = message.split()
    msg_type = msg_list[0]
    if msg_type == 'WHATSAT':
        server_logs.write("Received WHATSAT message.\n")
        return await handle_whatsat(message, at_time)
    if msg_type == 'IAMAT':
        server_logs.write("Received IAMAT message.\n")
        return await handle_iamat(message, at_time)
    if msg_type == "FLOODING":
        server_logs.write("Received FLOODING message.\n")
        await handle_flooding(message)
    else:
        server_logs.write("Received unknown message.\n")
        return handle_err(message)

async def run_forever():
    server = await asyncio.start_server(handle_echo, '127.0.0.1', server_ports[sname])
    async with server:
        await server.serve_forever()
    server.close()


# https://asyncio.readthedocs.io/en/latest/tcp_echo.html
def main():
    if len(sys.argv) != 2:
        print("Invalid number of arguments!")
        sys.exit(1)
    if sys.argv[1] not in server_ports.keys():
        print("No such server: ", sys.argv[1])
        sys.exit(1)
    global sname
    global server_logs
    sname = sys.argv[1]
    rec_server = sname
    server_logs = open(sname + "_logs.txt", "w+")
    try:
        asyncio.run(run_forever())
    except KeyboardInterrupt:
        pass


if __name__ == '__main__':
    main()