VCGRA_N_ROWS = 4
VCGRA_N_COLS = 4

CROSSBAR_N_SLAVES = 7
CROSSBAR_N_MASTERS = 8

ACLK = "aclk"
ARESET_N = "areset_n"

links = []
pe = []
xbar = []

def get_next_link_id() -> int:
    global lid
    next_lid = lid
    lid = lid + 1
    return next_lid

def make_connection(src, dst):
    link = Link(get_next_link_id())
    links.append(link)
    

class Link():

    def __init__(self, i):
        self.i = i

    def get_instance(self) -> str:
        return f"u{self.i}_axis_link"

    def get_declaration(self) -> str:
        return f"signal " + self.get_instance() + f" : axis_t;"
    
class FN():

    def __init__(self):
        pass

    def generate(self):
        pass

class LS():

    def __init__(self):
        pass

    def generate():
        pass

class XBAR():
    def __init__(self):
        pass

    def get_instance(self, i:int) -> str:
        f'''
        u{i}_ic : ic
            generic map(
                N_SLAVES    => {CROSSBAR_N_SLAVES},
                N_MASTERS   => {CROSSBAR_N_MASTERS}
            )
            port map (
                aclk        => {ACLK},
                areset_n    => {ARESET_N},
                -- AXIS Data Routing
                s           => s,
                m           => m
            );
        '''
    def get_declaration(self) -> str:
        pass

if __name__ == "__main__":
    print(
r'''
        ____ ____ ____      _       ____                           _             
__   __/ ___/ ___|  _ \    / \     / ___| ___ _ __   ___ _ __ __ _| |_ ___  _ __ 
\ \ / / |  | |  _| |_) |  / _ \   | |  _ / _ \ '_ \ / _ \ '__/ _` | __/ _ \| '__|
 \ V /| |__| |_| |  _ <  / ___ \  | |_| |  __/ | | |  __/ | | (_| | || (_) | |   
  \_/  \____\____|_| \_\/_/   \_\  \____|\___|_| |_|\___|_|  \__,_|\__\___/|_|   
'''
    )

    links = [Link(i) for i in range(CROSSBAR_N_MASTERS*CROSSBAR_N_SLAVES*VCGRA_N_COLS*VCGRA_N_ROWS)]
    for link in links:
        print(link.get_declaration())