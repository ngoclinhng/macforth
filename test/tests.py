from pathlib import Path
from testhelper import nasm, test_case
from testhelper import expect_status_to_be, expect_stdout_to_be
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

#
# TEST CASES.
#

def strlen_test():
    ls1 = 'Hello, world!'
    ls2 = 'This string is pretty long string'

    cases = [
        ('db 0', 0),
        ('db "",0', 0),
        ('db " ",0', 1),
        ('db "Hi",0', 2),
        ('db "{}",0'.format(ls1), len(ls1)),
        ('db "{}",0'.format(ls2), len(ls2)),
        ('db 0x31,0x32,0x33,0x34,0x35,0x36,0', 6)
    ]

    for (s, l) in cases:
        checker = expect_status_to_be(l)
        test_case('strlen_test', args=[s], checker=checker)

def prints_test():
    cases = [
        ('db 0', ''),
        ('db "",0', ''),
        ('db 10,0', '\n'),
        ('db 0x0a,0', '\n'),
        ('db 0x0A,0', '\n'),
        ('db "Hi!",0', 'Hi!'),
        ('db 0x48,0x69,0x21,0x00', 'Hi!'),
        ('db "Hello there"', 'Hello there'),
        ('db 0x48,0x65,0x6c,0x6c,0x6f,0x20,0x74,0x68,0x65,0x72,0x65,0x00',
         'Hello there')
    ]

    for (arg, out) in cases:
        checker = expect_stdout_to_be(out)
        test_case('prints_test', args=[arg], checker=checker)

def printn_test():
    checker = expect_stdout_to_be('\n')
    test_case('printn_test', args=[], checker=checker)

def printc_test():
    cases = [
        ('" "', ' '),
        ('0x20', ' '),
        (32, ' '),

        ('"\n"', '\n'),
        ('0x0a', '\n'),
        ('0x0A', '\n'),
        (10, '\n'),

        ('"a"', 'a'),
        ('0x61', 'a'),
        (97, 'a')
    ]

    for (arg, out) in cases:
        checker = expect_stdout_to_be(out)
        test_case('printc_test', args=[arg], checker=checker)

def printu_test():
    cases = [
        (0, '0'),
        ('0', '0'),
        ('0x0', '0'),
        ('"0"', '48'),
        ('0x30', '48'),

        (1, '1'),
        ('1', '1'),
        ('0x01', '1'),
        ('"1"', '49'),
        ('0x31', '49'),

        (10, '10'),
        ('10', '10'),
        ('0xa', '10'),
        ('0xA', '10'),

        (123, '123'),
        ('123', '123'),
        ('0x7b', '123'),
        ('0x7B', '123'),

        (1024, '1024'),
        ('1024', '1024'),
        ('0x0400', '1024'),

        (-1, '18446744073709551615'),
        ('-1', '18446744073709551615'),
        ('0xffffffffffffffff', '18446744073709551615')
    ]

    for (arg, out) in cases:
        checker = expect_stdout_to_be(out)
        test_case('printu_test', args=[arg], checker=checker)

def printi_test():
    cases = [
        (0, '0'),
        ('0', '0'),
        ('0x0', '0'),
        ('"0"', '48'),
        ('0x30', '48'),

        (1, '1'),
        ('1', '1'),
        ('0x01', '1'),
        ('"1"', '49'),
        ('0x31', '49'),

        (10, '10'),
        ('10', '10'),
        ('0xa', '10'),
        ('0xA', '10'),

        (123, '123'),
        ('123', '123'),
        ('0x7b', '123'),
        ('0x7B', '123'),

        (1024, '1024'),
        ('1024', '1024'),
        ('0x0400', '1024'),

        (-1, '-1'),
        ('-1', '-1'),
        ('0xffffffffffffffff', '-1'),

        (-12, '-12'),
        ('-12', '-12'),
        ('0xfffffffffffffff4', '-12'),

        (-123, '-123'),
        ('-123', '-123'),
        ('0xffffffffffffff85', '-123')
    ]

    for (arg, out) in cases:
        checker = expect_stdout_to_be(out)
        test_case('printi_test', args=[arg], checker=checker)

def readc_test():
    inputs = ['', ' ', '  ', 'a', 'hi', 'a b c', 'foo', 'bar']
    for i in inputs:
        checker = expect_status_to_be(0 if i == '' else ord(i[0]))
        test_case('readc_test', checker=checker, stdin=i)

def readw_test():
    cases = [
        ('', ''),
        (' ', ''),
        ('\n', ''),
        ('\r', ''),
        ('\t', ''),

        ('a', 'a'),
        (' a', 'a'),
        ('\na', 'a'),
        ('\ra', 'a'),
        ('\ta', 'a'),
        ('a b', 'a'),
        ('a\nb', 'a'),
        ('a\rb', 'a'),
        ('a\tb', 'a'),
        (' \t a\nb', 'a'),

        ('1', '1'),
        (' 1', '1'),
        ('\n1', '1'),
        ('\r1', '1'),
        ('\t1', '1'),
        ('1 2', '1'),
        ('1\n2', '1'),
        ('1\r2', '1'),
        ('1\t2', '1'),
        (' \t 1\n2', '1'),

        ('ab', 'ab'),
        (' ab', 'ab'),
        ('\nab', 'ab'),
        ('\rab', 'ab'),
        ('\tab', 'ab'),
        (' \tab\thello world!', 'ab'),

        ('1 and 2', '1'),
        ('foo and bar', 'foo'),
        ('1234567 and 8', '1234567'),
        ('abcdefg and hijklmn', 'abcdefg')
    ]

    for (i,e) in cases:
        checker = expect_stdout_to_be(e)
        test_case('readw_test', checker=checker, stdin=i)

    for (i,e) in cases:
        checker = expect_status_to_be(len(e))
        test_case('readw_test', checker=checker, stdin=i)

def parseu_test():
    cases = [
        ('0', '0', 1)
    ]

    for (i, o, _) in cases:
        checker = expect_stdout_to_be(o)
        test_case('parseu_test', checker=checker, args=[i])

if __name__ == '__main__':
    setup()
    strlen_test()
    prints_test()
    printn_test()
    printc_test()
    printu_test()
    printi_test()
    readc_test()
    readw_test()
    parseu_test()
