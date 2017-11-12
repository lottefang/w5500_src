import glob
import os
import subprocess
txt_path = 'F:\project\project\w5500\w5500_verilog_test\w5500_src\source'
try:
    os.mkdir(txt_path)
except OSError:
    pass
output_path='F:\project\project\w5500\w5500_verilog_test\w5500_src\source'
wf = open('output.txt', 'w',encoding='utf-8')

for wordfile in glob.glob(os.path.join(txt_path, '*.txt')):
    wordfile_path = os.path.abspath(wordfile)
    print ('process %s' % wordfile_path)
    f = open(wordfile_path, 'r')
    str=''
    data=[]
    for line in f.readlines():

        data.append(line)
        #print(line)
    t=0;
    i=0;
    str="";
    for x in range(len(data)):
        print(data[x])
        try:
            s=data[x]
            if (s.index('spi')>=0):
                i = i+1;
                
            str=str+'  mem[{0}]<=8\'h{1}{2};'.format(t+i,s[13],s[14]) 
            
        except Exception as e:
            if (i>0):
                str = 'mem[{0}]<=8\'d{1};'.format(t,i+1)+str+'\n'
                t = t+i+1;
                print(str)
                wf.write(str)
                str=''
            i = 0;
            pass
        else:
            pass
        finally:
            pass
        
wf.close()