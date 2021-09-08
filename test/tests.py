from pathlib import Path
from testhelper import nasm, test_case, expect_status_to_be
from termcolor import colored

def build_utils():
    target = 'utils'
    source = '../src/utils.asm'
    (ok, msg) = nasm(target, [source])
    if not ok:
        print(colored(msg, 'red'))

def setup():
    cwd = Path.cwd()

    # A directory to store all test object files.
    (cwd / 'obj').mkdir(exist_ok=True)

    # And a directory to store all test binary files.
    (cwd / 'bin').mkdir(exist_ok=True)

    # Build utils object file
    build_utils()

def strlen_test():
    cases = [
        ('db 0', 0),
        ('db "",0', 0),
        ('db " ",0', 1)
    ]

    for (s, l) in cases:
        checker = expect_status_to_be(l)
        test_case('strlen_test', args=[s], checker=checker)

if __name__ == '__main__':
    setup()
    strlen_test()
