import sys
from pathlib import Path
from testhelper import nasm, test_case
from testhelper import expect_status_to_be, expect_stdout_to_be
from termcolor import colored
from functools import reduce
from string import ascii_lowercase, ascii_uppercase, punctuation
import random

def build_utils():
    target = 'utils'
    source = '../../src/utils.asm'
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
# TEST SUITES.
#

def strlen_test():
    tcount = 0
    fcount = 0

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
        tcount += 1
        checker = expect_status_to_be(l)
        fcount += test_case('strlen_test', args=[s], checker=checker)

    return (tcount, fcount)

def prints_test():
    tcount = 0
    fcount = 0

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
        tcount += 1
        checker = expect_stdout_to_be(out)
        fcount += test_case('prints_test', args=[arg], checker=checker)

    return (tcount, fcount)

def printn_test():
    checker = expect_stdout_to_be('\n')
    fcount = test_case('printn_test', args=[], checker=checker)
    return (1, fcount)

def printc_test():
    tcount = 0
    fcount = 0

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
        tcount += 1
        checker = expect_stdout_to_be(out)
        fcount +=test_case('printc_test', args=[arg], checker=checker)

    return (tcount, fcount)

def printu_test():
    tcount = 0
    fcount = 0

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
        tcount += 1
        checker = expect_stdout_to_be(out)
        fcount += test_case('printu_test', args=[arg], checker=checker)

    return (tcount, fcount)

def printi_test():
    tcount = 0
    fcount = 0

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
        tcount += 1
        checker = expect_stdout_to_be(out)
        fcount += test_case('printi_test', args=[arg], checker=checker)

    return (tcount, fcount)

def readc_test():
    tcount = 0
    fcount = 0

    inputs = ['', ' ', '  ', 'a', 'hi', 'a b c', 'foo', 'bar']

    for i in inputs:
        tcount += 1
        checker = expect_status_to_be(0 if i == '' else ord(i[0]))
        fcount += test_case('readc_test', checker=checker, stdin=i)

    return (tcount, fcount)

def readw_test():
    tcount = 0
    fcount = 0

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
        tcount += 1
        checker = expect_stdout_to_be(e)
        fcount += test_case('readw_test', checker=checker, stdin=i)

    for (i,e) in cases:
        tcount += 1
        checker = expect_status_to_be(len(e))
        fcount += test_case('readw_test', checker=checker, stdin=i)

    return (tcount, fcount)

def parseu_test():
    tcount = 0
    fcount = 0

    cases = [
        ('"0"', '0', 1),
        ('"1"', '1', 1),
        ('"2"', '2', 1),
        ('"3"', '3', 1),
        ('"4"', '4', 1),
        ('"5"', '5', 1),
        ('"6"', '6', 1),
        ('"7"', '7', 1),
        ('"8"', '8', 1),
        ('"9"', '9', 1),

        ('0x30', '0', 1),
        ('0x31', '1', 1),
        ('0x32', '2', 1),
        ('0x33', '3', 1),
        ('0x34', '4', 1),
        ('0x35', '5', 1),
        ('0x36', '6', 1),
        ('0x37', '7', 1),
        ('0x38', '8', 1),
        ('0x39', '9', 1),

        ('"12"', '12', 2),
        ('0x31,0x32', '12', 2),
        ('"1",0x32', '12', 2),
        ('0x31,"2"', '12', 2),

        ('"123"', '123', 3),
        ('0x31,0x32,0x33', '123', 3),

        ('"012"', '12', 3),
        ('0x30,0x31,0x32', '12', 3),
        ('0x31,0x32,0x20,0x33', '12', 2),

        ('0x31,0x32,0x33,0x34,0x35,0x36,0x37,0x38,0x39', '123456789', 9),
        ('"123456789"', '123456789', 9),

        ('"4294967296"', '4294967296', 10),
        ('0x34,0x32,0x39,0x34,0x39,0x36,0x37,0x32,0x39,0x36', '4294967296',
         10),

        ('"18446744073709551615"', '18446744073709551615', 20),

        ('" 1"', '0', 0),
        ('"a1b2"', '0', 0),
        ('0x20,0x31', '0', 0)
    ]

    for (i, o, _) in cases:
        tcount += 1
        checker = expect_stdout_to_be(o)
        fcount += test_case('parseu_test', checker=checker, args=[i])

    for (i, _, s) in cases:
        tcount += 1
        checker = expect_status_to_be(s)
        fcount += test_case('parseu_test', checker=checker, args=[i])

    return (tcount, fcount)

def parsei_test():
    tcount = 0
    fcount = 0

    cases = [
        ('"0"', '0', 1),
        ('"1"', '1', 1),
        ('"2"', '2', 1),
        ('"3"', '3', 1),
        ('"4"', '4', 1),
        ('"5"', '5', 1),
        ('"6"', '6', 1),
        ('"7"', '7', 1),
        ('"8"', '8', 1),
        ('"9"', '9', 1),

        ('"-0"', '0', 2),
        ('"-1"', '-1', 2),
        ('"-2"', '-2', 2),
        ('"-3"', '-3', 2),
        ('"-4"', '-4', 2),
        ('"-5"', '-5', 2),
        ('"-6"', '-6', 2),
        ('"-7"', '-7', 2),
        ('"-8"', '-8', 2),
        ('"-9"', '-9', 2),

        ('"+0"', '0', 1),
        ('"+1"', '1', 1),
        ('"+2"', '2', 1),
        ('"+3"', '3', 1),
        ('"+4"', '4', 1),
        ('"+5"', '5', 1),
        ('"+6"', '6', 1),
        ('"+7"', '7', 1),
        ('"+8"', '8', 1),
        ('"+9"', '9', 1),

        ('0x30', '0', 1),
        ('0x31', '1', 1),
        ('0x32', '2', 1),
        ('0x33', '3', 1),
        ('0x34', '4', 1),
        ('0x35', '5', 1),
        ('0x36', '6', 1),
        ('0x37', '7', 1),
        ('0x38', '8', 1),
        ('0x39', '9', 1),

        ('0x2d,0x30', '0', 2),
        ('0x2d,0x31', '-1', 2),
        ('0x2d,0x32', '-2', 2),
        ('0x2d,0x33', '-3', 2),
        ('0x2d,0x34', '-4', 2),
        ('0x2d,0x35', '-5', 2),
        ('0x2d,0x36', '-6', 2),
        ('0x2d,0x37', '-7', 2),
        ('0x2d,0x38', '-8', 2),
        ('0x2d,0x39', '-9', 2),

        ('0x2b,0x30', '0', 1),
        ('0x2b,0x31', '1', 1),
        ('0x2b,0x32', '2', 1),
        ('0x2b,0x33', '3', 1),
        ('0x2b,0x34', '4', 1),
        ('0x2b,0x35', '5', 1),
        ('0x2b,0x36', '6', 1),
        ('0x2b,0x37', '7', 1),
        ('0x2b,0x38', '8', 1),
        ('0x2b,0x39', '9', 1),

        ('"12"', '12', 2),
        ('0x31,0x32', '12', 2),
        ('0x2b,0x31,0x32', '12', 2),
        ('"-12"', '-12', 3),
        ('0x2d,0x31,0x32', '-12', 3),

        ('"123456789"', '123456789', 9),
        ('0x31,0x32,0x33,0x34,0x35,0x36,0x37,0x38,0x39', '123456789', 9),
        ('0x2b,0x31,0x32,0x33,0x34,0x35,0x36,0x37,0x38,0x39', '123456789',
         9),
        ('"-123456789"', '-123456789', 10),
        ('0x2d,0x31,0x32,0x33,0x34,0x35,0x36,0x37,0x38,0x39', '-123456789',
         10),

        ('"4294967296"', '4294967296', 10),
        ('0x34,0x32,0x39,0x34,0x39,0x36,0x37,0x32,0x39,0x36', '4294967296',
         10),
        ('0x2b,0x34,0x32,0x39,0x34,0x39,0x36,0x37,0x32,0x39,0x36',
         '4294967296', 10),
        ('"-4294967296"', '-4294967296', 11),
        ('0x2d,0x34,0x32,0x39,0x34,0x39,0x36,0x37,0x32,0x39,0x36',
         '-4294967296', 11)
    ]

    for (i, o, _) in cases:
        tcount += 1
        checker = expect_stdout_to_be(o)
        fcount += test_case('parsei_test', checker=checker, args=[i])

    for (i, _, s) in cases:
        tcount += 1
        checker = expect_status_to_be(s)
        fcount += test_case('parsei_test', checker=checker, args=[i])

    return (tcount, fcount)

def strequ_test():
    tcount = 0
    fcount = 0

    cases = [
        ('', ''),
        ('a', 'a'),
        ('1', '1'),
        ('abc', 'abc'),
        ('123', '123'),
        ('Hello, world!', 'Hello, world!'),
        ('Hello, world!', 'Hello, world'),
        ('Foo and Bar', 'Foo and Bar'),
        ('Foo and bar', 'Foo and Bar'),
        ('something', '')
    ]

    for (s1, s2) in cases:
        tcount += 1
        checker = expect_status_to_be(1 if s1 == s2 else 0)
        args = [repr(s1), repr(s2)]
        fcount += test_case('strequ_test', args=args, checker=checker)

    return (tcount, fcount)

def strcpy_test():
    tcount = 0
    fcount = 0

    cases = [
        ('', '', 1),
        (' ', ' ', 1),
        ('a', 'a', 1),
        ('ab', 'ab', 1),
        ('abc', 'abc', 1),
        ('a b c', 'a b c', 1),
        ('Hi', 'Hi', 1),
        ('bye bye', 'bye bye', 1),
        ('Hello', 'Hello', 1),
        ('1234567', '1234567', 1),
        ('abcdefg', 'abcdefg', 1),
        ('1+1=3', '1+1=3', 1),

        # Overflow tests (buffer size is 8 bytes. See strcpy_test.asm)
        ('12345678', '', 0),
        ('abcdefgh', '', 0),
        ('Hello, world!', '', 0)
    ]

    for (i, o, _) in cases:
        tcount += 1
        checker = expect_stdout_to_be(o)
        fcount += test_case('strcpy_test', args=[repr(i)], checker=checker)

    for (i, _, s) in cases:
        tcount += 1
        checker = expect_status_to_be(s)
        fcount += test_case('strcpy_test', args=[repr(i)], checker=checker)

    return (tcount, fcount)

def tolower_test():
    (tcount, fcount) = (0, 0)

    i1 = [c for c in ascii_uppercase]
    o1 = [ord(c) for c in ascii_lowercase]

    i2 = [c for c in ascii_lowercase]
    o2 = o1

    i3 = [p for p in punctuation]
    o3 = [ord(p) for p in i3]

    cases = zip(i1 + i2 + i3, o1 + o2 + o3)

    for (i, o) in cases:
        tcount += 1
        checker = expect_status_to_be(o)
        args = [repr(i)]
        fcount += test_case('tolower_test', checker=checker, args=args)

    return (tcount, fcount)

def istrequ_test():
    (tcount, fcount) = (0, 0)

    cases = [
        ('', ''),
        ('a', 'a'),
        ('a', 'A'),
        ('1', '1'),
        ('abc', 'abc'),
        ('aBc', 'abc'),
        ('ABC', 'abc'),
        ('123', '123'),
        ('Hello, world!', 'Hello, world!'),
        ('Hello, world!', 'hello, world!'),
        ('Hello, World!', 'hello, world!'),
        ('HELLO, World!', 'hello, world!'),
        ('HELLO, WORLD!', 'hello, world!'),
        ('FOO', 'foo'),
        ('BAR', 'bar'),
        ('bAR', 'bar'),
        ('R>', 'r>'),
        ('>R', '>r'),
        ('.S', '.s')
    ]

    for (s1, s2) in cases:
        tcount += 1
        args = [repr(s1), repr(s2)]
        checker = expect_status_to_be(1 if s1.lower() == s2.lower() else 0)
        fcount += test_case('istrequ_test', args=args, checker=checker)

    return (tcount, fcount)

TEST_SUITES = {
    'strlen': strlen_test,
    'prints': prints_test,
    'printn': printn_test,
    'printc': printc_test,
    'printu': printu_test,
    'printi': printi_test,
    'readc': readc_test,
    'readw': readw_test,
    'parseu': parseu_test,
    'parsei': parsei_test,
    'strequ': strequ_test,
    'strcpy': strcpy_test,
    'tolower': tolower_test,
    'istrequ': istrequ_test
}

def print_summary(summary):
    (total_count, failure_count) = summary

    s1 = '{} tests, '.format(total_count)
    s2 = '{} failures'.format(failure_count)

    print('-' * len(s1 + s2))

    s1 = colored(s1, 'green')
    s2 = colored(s2, 'red' if failure_count else 'green')
    print(s1 + s2)

if __name__ == '__main__':
    setup()

    suites = []
    argv = sys.argv

    if len(argv) > 1:
        suites = [TEST_SUITES.get(arg) for arg in argv]
        suites = filter(lambda x : x is not None, suites)
    else:
        suites = TEST_SUITES.values()

    suites = list(suites)
    random.shuffle(suites)

    summary = [t() for t in suites]
    summary = reduce(lambda a,x : (a[0]+x[0], a[1]+x[1]), summary, (0, 0))
    print_summary(summary)
