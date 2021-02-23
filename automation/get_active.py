"""
Active User Finder

Author: Neil Wang
Date: 2021/02/21
Version: 0.1
Description: Read from two files and compare them (all and suspended in this case), then print out all the users
which are not in the suspended file.
This is more acurate than the 'comm' command in bash since the trailing newline will be removed before comparing.
"""

def find_active(all_users, suspended_users):
    for i in all_users:
        if i not in suspended_users:
            print(i)


def load_files(all, suspend):
    with open(all, 'r') as file1:
        all_users = file1.read().splitlines()
    with open(suspend, 'r') as file2:
        suspended_users = file2.read().splitlines()
    find_active(all_users, suspended_users)

def main():
    load_files("all.txt", "suspended.txt")


if __name__ == '__main__':
    main()
