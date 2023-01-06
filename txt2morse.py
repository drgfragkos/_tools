# play music on the PC internal speaker
# tested with Python24 on a Windows XP computer  vegaseat  15aug2005
# (c) gfragkos 2005
 
import winsound
import time
import string
import sys
 
# the notes
P = 0   # pause
C = 1
CS = 2  # C sharp
D = 3
DS = 4
E = 5
F = 6
FS = 7
G = 8
GS = 9
A = 10
AS = 11
B = 12
 
EN = 100  # eighth note
QN = 200  # quarter note
HN = 400  # half note
FN = 800  # full note
 
def play(octave, note, duration):
    """in octave (1-8), play note (C=1 to B=12), duration (msec)"""
    if note == 0:    # a pause
        time.sleep(duration/1000)
        return
    frequency = 32.7032           # C1
    for k in range(0, octave):    # compute C in given octave
        frequency *= 2
 
    for k in range(0, note):      # compute frequency of given note
        frequency *= 1.059463094  # 1.059463094 = 12th root of 2
    time.sleep(0.010)             # delay between keys 
 
    winsound.Beep(int(frequency), duration)
 
def bigben():
    play(4,5,HN)
    play(4,1,HN)
    play(4,3,HN)
    play(3,8,HN+QN); play(3,0,QN)
    play(3,8,HN)
    play(4,3,HN)
    play(4,5,HN)
    play(4,1,HN+QN)



#http://en.wikipedia.org/wiki/Morse_code
    
def A():
    """Convert A to Morse"""
    play(4,10,QN)
    play(4,10,HN)

def B():
    """Convert B to Morse"""
    play(4,10,HN)
    play(4,10,QN)
    play(4,10,QN)
    play(4,10,QN)

def C():
    """Convert C to Morse"""
    play(4,10,HN)
    play(4,10,QN)
    play(4,10,HN)
    play(4,10,QN)

def D():
    """Convert D to Morse"""
    play(4,10,HN)
    play(4,10,QN)
    play(4,10,QN)

def E():
    """Convert E to Morse"""
    play(4,10,QN)

def F():
    """Convert F to Morse"""
    play(4,10,QN)
    play(4,10,QN)
    play(4,10,HN)
    play(4,10,QN)

def G():
    """Convert G to Morse"""
    play(4,10,HN)
    play(4,10,HN)
    play(4,10,QN)

def H():
    """Convert H to Morse"""
    play(4,10,QN)
    play(4,10,QN)
    play(4,10,QN)
    play(4,10,QN)

def I():
    """Convert I to Morse"""
    play(4,10,QN)
    play(4,10,QN)

def J():
    """Convert B to Morse"""
    play(4,10,QN)
    play(4,10,HN)
    play(4,10,HN)
    play(4,10,HN)

def K():
    """Convert K to Morse"""
    play(4,10,HN)
    play(4,10,QN)
    play(4,10,HN)

def L():
    """Convert L to Morse"""
    play(4,10,QN)
    play(4,10,HN)
    play(4,10,QN)
    play(4,10,QN)

def M():
    """Convert M to Morse"""
    play(4,10,HN)
    play(4,10,HN)

def N():
    """Convert N to Morse"""
    play(4,10,HN)
    play(4,10,QN)

def O():
    """Convert O to Morse"""
    play(4,10,HN)
    play(4,10,HN)
    play(4,10,HN)

def P():
    """Convert P to Morse"""
    play(4,10,QN)
    play(4,10,HN)
    play(4,10,HN)
    play(4,10,QN)

def Q():
    """Convert Q to Morse"""
    play(4,10,HN)
    play(4,10,HN)
    play(4,10,QN)
    play(4,10,HN)

def R():
    """Convert R to Morse"""
    play(4,10,QN)
    play(4,10,HN)
    play(4,10,QN)

def S():
    """Convert S to Morse"""
    play(4,10,QN)
    play(4,10,QN)
    play(4,10,QN)

def T():
    """Convert T to Morse"""
    play(4,10,HN)

def U():
    """Convert U to Morse"""
    play(4,10,QN)
    play(4,10,QN)
    play(4,10,HN)

def V():
    """Convert V to Morse"""
    play(4,10,QN)
    play(4,10,QN)
    play(4,10,QN)
    play(4,10,HN)

def W():
    """Convert W to Morse"""
    play(4,10,QN)
    play(4,10,HN)
    play(4,10,HN)

def X():
    """Convert X to Morse"""
    play(4,10,HN)
    play(4,10,QN)
    play(4,10,QN)
    play(4,10,HN)
    
def Y():
    """Convert Y to Morse"""
    play(4,10,HN)
    play(4,10,QN)
    play(4,10,HN)
    play(4,10,HN)

def Z():
    """Convert Z to Morse"""
    play(4,10,HN)
    play(4,10,HN)
    play(4,10,QN)
    play(4,10,QN)
    
def num0():
    """Convert 0 to Morse"""
    play(4,10,HN)
    play(4,10,HN)
    play(4,10,HN)
    play(4,10,HN)
    play(4,10,HN)
    
def num1():
    """Convert 1 to Morse"""
    play(4,10,QN)
    play(4,10,HN)
    play(4,10,HN)
    play(4,10,HN)
    play(4,10,HN)

def num2():
    """Convert 2 to Morse"""
    play(4,10,QN)
    play(4,10,QN)
    play(4,10,HN)
    play(4,10,HN)
    play(4,10,HN)

def num3():
    """Convert 3 to Morse"""
    play(4,10,QN)
    play(4,10,QN)
    play(4,10,QN)
    play(4,10,HN)
    play(4,10,HN)
    
def num4():
    """Convert 4 to Morse"""
    play(4,10,QN)
    play(4,10,QN)
    play(4,10,QN)
    play(4,10,QN)
    play(4,10,HN)
    
def num5():
    """Convert 5 to Morse"""
    play(4,10,QN)
    play(4,10,QN)
    play(4,10,QN)
    play(4,10,QN)
    play(4,10,QN)
    
def num6():
    """Convert 6 to Morse"""
    play(4,10,HN)
    play(4,10,QN)
    play(4,10,QN)
    play(4,10,QN)
    play(4,10,QN)
    
def num7():
    """Convert 7 to Morse"""
    play(4,10,HN)
    play(4,10,HN)
    play(4,10,QN)
    play(4,10,QN)
    play(4,10,QN)
    
def num8():
    """Convert 8 to Morse"""
    play(4,10,HN)
    play(4,10,HN)
    play(4,10,HN)
    play(4,10,QN)
    play(4,10,QN)
    
def num9():
    """Convert 9 to Morse"""
    play(4,10,HN)
    play(4,10,HN)
    play(4,10,HN)
    play(4,10,HN)
    play(4,10,QN)

def space():
    time.sleep(100/1000)

def neword():
    time.sleep(1000/1000)
    

#Main
#-----------
#

#while inpt!="#":
print ".:txt2morse:. - Enter # to exit."
print '='*72

while 1:
    inpt = raw_input("\nEnter Text: ")
    if inpt == "#":
        break
    print "Converting [" + inpt + "] into Morse Code\n"
    charlist = list(string.lower(inpt))
    #print charlist
    for dig in charlist:
        #print dig
        if dig==' ':
            neword()
        elif dig=='a':
            A()
        elif dig=='b':
            B()
        elif dig=='c':
            C()
        elif dig=='d':
            D()
        elif dig=='e':
            E()
        elif dig=='f':
            F()
        elif dig=='g':
            G()
        elif dig=='h':
            H()
        elif dig=='i':
            I()
        elif dig=='j':
            J()
        elif dig=='k':
            K()
        elif dig=='l':
            L()
        elif dig=='m':
            M()
        elif dig=='n':
            N()    
        elif dig=='o':
            O()
        elif dig=='p':
            P()
        elif dig=='q':
            Q()
        elif dig=='r':
            R()
        elif dig=='s':
            S()
        elif dig=='t':
            T()
        elif dig=='u':
            U()
        elif dig=='v':
            V()
        elif dig=='w':
            W()
        elif dig=='x':
            X()
        elif dig=='y':
            Y()
        elif dig=='z':
            Z()
        elif dig=='0':
            num0()
        elif dig=='1':
            num1()
        elif dig=='2':
            num2()
        elif dig=='3':
            num3()
        elif dig=='4':
            num4()
        elif dig=='5':
            num5()
        elif dig=='6':
            num6()
        elif dig=='7':
            num7()
        elif dig=='8':
            num8()
        elif dig=='9':
            num9()
        elif dig=='+':
            print "There is no + sign in morse, playing BigBen insteed!"
            bigben()


