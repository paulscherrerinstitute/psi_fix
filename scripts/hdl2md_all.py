# ======================================================================
# Script that generate MD file template for PSI library
# Benoît Stef - WBBA 311
# ======================================================================
import pandas as pd
import re
import os
from os import listdir
from os.path import isfile, join

print('select to file to convert:')
path_file = input()

# ======================================================================
# Discard pkg from the entire repo
# ======================================================================
c = 0
onlyfiles = [f for f in listdir(path_file) if isfile(join(path_file, f))]
nPop = []
newList = []

for p in range(0, len(onlyfiles)):
    test = onlyfiles[p].split('pkg')
    if len(test) == 2:
        nPop.append(p)
    else:
        newList.append(onlyfiles[p])

# ======================================================================
# Lists creation loop, file by file
# ======================================================================
i = 0
for i in range (0, len(onlyfiles)):
    # definition for port processing
    ports = []
    name = []
    vector = []
    size = []
    desc = []
    cmt = []
    direction = []
    count = 0
    start = 0
    gene = 0

    # definition for generic processing
    gName = []
    gType = []
    gVal = []
    gDesc = []
    gCmt = []

    start_port = re.compile(r'port')
    end_entity = re.compile(r'end')
    start_generic = re.compile(r'generic')
    end_element = re.compile(r'[);]')

    with open(path_file+'/'+onlyfiles[i]) as fh:  # open text file
        lines = [l.strip() for l in fh.readlines()]
        for l in lines:

            # check start of entity
            if re.match(start_port, l.lower()):
                start = 1
            elif re.match(end_entity, l.lower()):
                start = 0
                break

            if re.match(start_generic, l.lower()):
                gene = 1
            elif re.match(end_element, l.lower()):
                gene = 0

            # process parsing of generics
            if gene == 1:
                parts = re.sub( '\s+', ' ', l.lower() ).split( ':' )
               # print(parts)
                if len( parts ) > 1:
                    gName.append( parts[0] )
                    gType.append( parts[1].split()[0] )
                    gCmt = parts[-1].split( '--' )
                    if len( gCmt ) == 2:
                        gDesc.append( parts[-1].split( '--' )[1] )
                    else:
                        gDesc.append( 'N.A' )

            # Process parsing of ports
            if start == 1:
                parts = re.sub('\s+', ' ', l.lower()).split(':')
                if len(parts) == 2:
                    ports = parts[0].strip()
                    vector = parts[-1].split('(')

                    # extract port of the file and put into lists
                    if ports:
                        if not(ports[0:2] == "--"):
                            name.append(ports)
                            size.append(vector[-1].split(" ")[0])
                            cmt.append(parts[-1].split(';')[-1])
                            direction.append((vector[0].strip()[0]))

                            # description auto
                            if cmt[count]:
                                desc.append(parts[-1].split('--')[-1])
                            else:
                                desc.append("N.A" )
                            count += 1
    # ======================================================================
    # Debug print
    # ======================================================================
    # print(name)
    # print(direction)
    # print(size)
    # print(desc)

    # print(gName)
    # print(gType)
    # print(gVal)
    # print(gDesc)

    # Create dict to feed into pandas Data Frame to write MD file ^^ useless piece of code
    for i in range(0, len(size)):
        if not size[i] or size[i] == '0':
            size[i] = '1'

    # ======================================================================
    # Write to the File and a bit formatting
    # ======================================================================
    md_name = os.path.basename(fh.name)
    md_name = md_name.split('.')
    # print(md_name)
    df1 = pd.DataFrame({"Name": gName, "type": gType, "Description": gDesc})
    df1 = df1.set_index('Name')
    df2 = pd.DataFrame({"Name": name, "In/Out": direction, "Length": size, "Description": desc})
    df2 = df2.set_index('Name')

    f = open('../doc/'+md_name[0]+".md", "w+")  # write into file
    f.write('<img align="right" src="../doc/psi_logo.png">')
    f.write('\n')
    f.write('***\n')
    f.write('\n')
    f.write('# '+md_name[0])
    f.write('\n')
    f.write(" - VHDL source: ["+md_name[0]+"](../hdl/"+md_name[0]+".vhd)\n")
    f.write(" - Testbench source: ["+md_name[0]+"_tb.vhd](../testbench/"+md_name[0]+"_tb.vhd)\n")
    f.write('\n')
    f.write('### Description')
    f.write('\n')
    f.write("*INSERT YOUR TEXT*")
    f.write('\n')
    f.write('### Generics\n')
    f.write(df1.to_markdown())
    f.write('\n')
    f.write('\n')
    f.write('### Interfaces\n')
    f.write(df2.to_markdown())

    f.close()