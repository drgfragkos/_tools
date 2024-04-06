import random
import string

def generate_license_key():
    blocks = []
    for i in range(5):
        block = ''.join(random.choices(string.ascii_uppercase + string.digits, k=5))
        blocks.append(block)
    key = '-'.join(blocks)
    if validate_license_key(key):
        return key
    else:
        return generate_license_key()

def validate_license_key(key):
    key = key.replace('-', '')
    if len(key) != 25:
        return False
    digits = []
    for c in key:
        if c.isdigit():
            digits.append(int(c))
        elif c.isalpha():
            digits.append(ord(c) - ord('A') + 10)
        else:
            return False
    check = sum(digits[::-2] + [sum(divmod(d * 2, 10)) for d in digits[-2::-2]]) % 10
    return check == 0

# example usage
for i in range(10):
    key = generate_license_key()
    print(key)
