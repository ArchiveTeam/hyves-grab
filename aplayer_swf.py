#!/usr/bin/python
'''Give me the ue and I'll "decrypt" it for you!'''
import base64
import sys


def decrypthelper(text, password):
    local4 = []
    local5 = 0
    while local5 < len(text):
        local4.append(((ord(text[local5]) - ord(password[local5 % len(password)])) + 256) % 256)
        local5 += 1
    return ''.join([chr(c) for c in local4])


def decrypt(text, password):
    local4 = text[0:9]
    local5 = text[9:]
    local6 = decrypthelper(local4, password)
    return decrypthelper(local5, local6)


def decryptUE(ue):
    return decrypt(base64.b64decode(ue), "aulos")


if __name__ == '__main__':
    ue = sys.argv[1]
    print(decryptUE(ue))
