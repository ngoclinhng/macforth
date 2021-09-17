import sys
from pathlib import Path
from testhelper import nasm, test_case
from testhelper import expect_status_to_be, expect_stdout_to_be
from termcolor import colored
from functools import reduce
import random

def build_utils():
    target = 'utils'
    source = '../../src/utils.asm'
    (ok, msg) = nasm(target, [source])
    if not ok:
        print(colored(msg, 'red'))

def build_next():
    target = 'next'
    source = '../../src/next.asm'
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

    # Build next object file
    build_next()

#
# TEST SUITES.
#

def init_test():
    checker = expect_stdout_to_be('OK')
    fcount = test_case('init_test', args=[], checker=checker)
    return (1, fcount)


def next_test():
    checker = expect_status_to_be(0)
    fcount = test_case('next_test', args=[], checker=checker)
    return (1, fcount)

def find_test():
    tcount = 0
    fcount = 0

    cases = [
        ('foo', 'foo', 'found'),
        ('bar', 'bar', 'found'),
        ('baz', 'baz', 'found'),
        ('push-string-addr', 'push_string_addr', 'found'),
        ('check-find', 'check_find', 'found'),
        ('terminate', 'terminate', 'found'),
        ('init', 'init', 'found'),
        ('find', 'find', 'found'),

        ('thing', None, 'not_found')
    ]

    for (s, c, o) in cases:
        tcount += 1
        checker = expect_stdout_to_be(o)
        args = [repr(s)] if not c else [repr(s), c]
        fcount += test_case('find_test', args=args, checker=checker)

    return (tcount, fcount)

def ibuf_test():
    checker = expect_stdout_to_be('OK')
    fcount = test_case('ibuf_test', args=[], checker=checker)
    return (1, fcount)

def word_test():
    tcount = 0
    fcount = 0

    cases = [
        (':', ':'),
        (' :', ':'),
        (': thing', ':'),

        (';', ';'),
        (' ;', ';'),
        (' ;\n', ';'),

        ('.', '.'),
        (',', ','),
        ('."', '."'),

        ('+', '+'),
        (' + ', '+'),
        ('*', '*'),
        (' * ', '*'),
        ('+*', '+*'),
        (' +* ', '+*'),

        ('1 2 +', '1'),
        ('23 45 *', '23'),
        ('-13 60 -', '-13'),


        ('thing', 'thing'),
        ('thing foo bar ;', 'thing'),
        ('', '')
    ]

    for (i, o) in cases:
        tcount += 1
        checker = expect_stdout_to_be(o)
        fcount += test_case('word_test', checker=checker, stdin=i)

    return (tcount, fcount)


def dup_test():
    checker = expect_stdout_to_be('OK')
    fcount = test_case('dup_test', checker=checker)
    return (1, fcount)

def rot_test():
    tcount = 0
    fcount = 0

    cases = [
        # ( 1 2 3 -- 2 3 1)
        ([1, 2, 3], '1 3 2'),

        # ( 5 73 -16 -- 73 -16 5 )
        ([5, 73, -16], '5 -16 73'),

        # ( 3 2 1 -- 2 1 3 )
        ([3, 2, 1], '3 1 2')
    ]

    for (args, out) in cases:
        tcount += 1
        checker = expect_stdout_to_be(out)
        fcount += test_case('rot_test', checker=checker, args=args)

    return (tcount, fcount)

def cfa_test():
    tcount = 0
    fcount = 0

    cases = [
        ('cfa', 'cfa', 'OK'),
        ('init', 'init', 'OK'),
        ('find', 'find', 'OK'),
        ('dup', 'dup', 'OK'),
        ('thing', None, 'No such word was found')
    ]

    for (s, c, o) in cases:
        tcount += 1
        checker = expect_stdout_to_be(o)
        args = [repr(s), c] if c else [repr(s)]
        fcount += test_case('cfa_test', checker=checker, args=args)

    return (tcount, fcount)

def gotz_test():
    tcount = 0
    fcount = 0

    cases = [
        (0, 'ISZERO'),
        (1, 'NOZERO'),
        (-1, 'NOZERO'),
        (123, 'NOZERO')
    ]

    for (i, o) in cases:
        tcount += 1
        checker = expect_stdout_to_be(o)
        fcount += test_case('gotz_test', checker=checker, args=[i])

    return (tcount, fcount)

def drop_test():
    tcount = 0
    fcount = 0

    cases = [
        ([2, 5, 73, -16], '73 5 2'),
        ([1, 2, 3, 4], '3 2 1')
    ]

    for (args, o) in cases:
        tcount += 1
        checker = expect_stdout_to_be(o)
        fcount += test_case('drop_test', checker=checker, args=args)

    return (tcount, fcount)

def docolon_test():
    checker = expect_stdout_to_be('colon: foo bar. Bye')
    fcount = test_case('docolon_test', checker=checker)
    return (1, fcount)

def lit_test():
    tcount = 0
    fcount = 0

    cases = [
        ('Hello', 1, 'Hello 1'),
        ('Hi', 123, 'Hi 123'),
        ('Hello, world!', -72, 'Hello, world! -72')
    ]

    for (s, n, o) in cases:
        tcount += 1
        checker = expect_stdout_to_be(o)
        args = [repr(s), n]
        fcount += test_case('lit_test', checker=checker, args=args)

    return (tcount, fcount)

TEST_SUITES = {
    'init': init_test,
    'next': next_test,
    'find': find_test,
    'ibuf': ibuf_test,
    'word': word_test,
    'dup': dup_test,
    'rot': rot_test,
    'drop': drop_test,
    'lit': lit_test,
    'cfa': cfa_test,
    'gotz': gotz_test,
    'docolon': docolon_test
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
