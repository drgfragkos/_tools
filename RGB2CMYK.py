
#Convert RGB values to CMYK

# Ask the user to enter a string
string = input("Enter RGB values in CSV format (eg: 00,125,08): ")

# Split the string into a list of values
values = string.split(',')

# Check if the values are valid integers between 0 and 255
if len(values) == 3:
    if all(val.isdigit() for val in values):
        if all(0 <= int(val) <= 255 for val in values):
            # Print the values to the screen
            print("RGB values entered: ", values)
            
            # Convert the values to integers and assign them to variables R, G, and B
            R, G, B = [int(val) for val in values]
            
            # Print the values to the screen
            #print("R:", R)
            #print("G:", G)
            #print("B:", B)
            
            c = 1 - (R / 255)
            m = 1 - (G / 255)
            y = 1 - (B / 255)
            k = min(c, m, y)

            if k == 1:
                c = 0
                m = 0
                y = 0
            else:
                c = (c - k) / (1 - k)
                m = (m - k) / (1 - k)
                y = (y - k) / (1 - k)
            
            #Round to 2 decimals if float, or Round to Integer if not float.
            cmyk_arr_val = [c, m, y, k]
            cmyk_arr_let = ('C', 'M', 'Y', 'K')

            for i, value in enumerate(cmyk_arr_val):
                rounded_result = round(value, 2)
                if rounded_result.is_integer():
                    print(f'{cmyk_arr_let[i]}: {int(rounded_result)}')
                else:
                    print(f'{cmyk_arr_let[i]}: {rounded_result}')
                
            #print("-----")
            #print("C:", round(c,2))
            #print("M:", round(m,2))
            #print("Y:", round(y,2))
            #print("K:", round(k,2))

        else:
            print("Error: One or more values are not between 0 and 255.")
    else:
        print("Error: One or more values are not integers.")
else:
    print("Error: The string does not contain three values.")



