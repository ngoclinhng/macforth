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
    (tcount, fcount) = (0, 0)

    cases = [
        ('foo', 'foo', 'found'),
        ('FOO', 'foo', 'found'),
        ('FoO', 'foo', 'found'),

        ('bar', 'bar', 'found'),
        ('BAR', 'bar', 'found'),
        ('bAR', 'bar', 'found'),

        ('baz', 'baz', 'found'),
        ('baZ', 'baz', 'found'),
        ('Baz', 'baz', 'found'),
        ('BAZ', 'baz', 'found'),
        ('BaZ', 'baz', 'found'),

        ('push-string-addr', 'push_string_addr', 'found'),
        ('PUSH-STRING-ADDR', 'push_string_addr', 'found'),
        ('Push-String-Addr', 'push_string_addr', 'found'),
        ('PuSh-StrING-AdDr', 'push_string_addr', 'found'),

        ('check-find', 'check_find', 'found'),
        ('CHECK-FIND', 'check_find', 'found'),
        ('chEck-FIND', 'check_find', 'found'),
        ('CheCk-fInd', 'check_find', 'found'),

        ('terminate', 'terminate', 'found'),
        ('Terminate', 'terminate', 'found'),
        ('TERMINATE', 'terminate', 'found'),

        ('init', 'init', 'found'),
        ('INIT', 'init', 'found'),
        ('inIt', 'init', 'found'),

        ('find', 'find', 'found'),
        ('FIND', 'find', 'found'),
        ('fInD', 'find', 'found'),

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

def prints_test():
    tcount = 0
    fcount = 0

    inputs = [
        ':', ';', '.', '+', '-', '/', ',', '.s', '.S', 'foo bar baz',
        'Error: THING is undefined'
    ]

    for s in inputs:
        tcount += 1
        checker = expect_stdout_to_be(s)
        fcount += test_case('prints_test', checker=checker, args=[repr(s)])

    return (tcount, fcount)

def printe_test():
    (tcount, fcount) = (0, 0)

    cases = [
        ('foo', 1),
        ('FOO', 11),
        ('bar', 17),
        ('BAR', 2),
        ('thing', 20),
        ('Thing', 10),
        ('THING', 3),
        ('THIng', 4),
        ('TING', 15),
        ('TONG', 25)
    ]

    for (string, status) in cases:
        tcount += 1
        expected = 'Error: {} is undefined\n'.format(string)
        checker = expect_stdout_to_be(expected)
        args = [repr(string), status]
        fcount += test_case('printe_test', checker=checker, args=args)

    for (string, status) in cases:
        tcount += 1
        checker = expect_status_to_be(status)
        args = [repr(string), status]
        fcount += test_case('printe_test', checker=checker, args=args)

    return (tcount, fcount)

def execute_test():
    (tcount, fcount) = (0, 0)

    cases = [
        ('Hi', 1),
        ('Hello', 2),
        ('foo', 3),
        ('bar', 4),
        ('baz', 5),
        ('Hi, there!', 15)
    ]

    for (string, status) in cases:
        tcount += 1
        checker = expect_stdout_to_be(string)
        args = [repr(string), status]
        fcount += test_case('execute_test', checker=checker, args=args)

    for (string, status) in cases:
        tcount += 1
        checker = expect_status_to_be(status)
        args = [repr(string), status]
        fcount += test_case('execute_test', checker=checker, args=args)

    return (tcount, fcount)

def dot_test():
    (tcount, fcount) = (0, 0)

    cases = [
        [1, 2, 3],
        [11, -2, 128],
        [10, 10, 10],
        [-1, -1, -1],
        [343, 545, -23123]
    ]

    for args in cases:
        tcount += 1

        err = 'Error: stack is empty\n'
        rargs = reversed(args)
        expected = '\n'.join([str(i) for i in rargs] + [err])
        checker = expect_stdout_to_be(expected)

        fcount += test_case('dot_test', checker=checker, args=args)

    return (tcount, fcount)

def sub_test():
    (tcount, fcount) = (0, 0)

    cases = [
        [1, 2, 3],
        [1, 3, 2],
        [5, 73, -16],
        [34, -23, 56],
        [0, 0, 0],
        [1, 1, 1],
        [-3, -6, -7]
    ]

    for args in cases:
        tcount += 1
        (arg0, arg1, arg2) = args
        expected = '{} {}'.format(arg1 - arg2, arg0)
        checker = expect_stdout_to_be(expected)
        fcount += test_case('sub_test', checker=checker, args=args)

    for args in cases:
        tcount += 1
        checker = expect_status_to_be(0)
        fcount += test_case('sub_test', checker=checker, args=args)

    return (tcount, fcount)

def repl_word_test():
    (tcount, fcount) = (0, 0)

    cases = [
        ('', '(0,0)'),
        (' ', '(0,0)'),

        (' \n', '({},{})'.format(0, ord('\n'))),
        (' \n ', '({},{})'.format(0, ord('\n'))),
        (' \nabc', '({},{})'.format(0, ord('\n'))),
        (' \n abc', '({},{})'.format(0, ord('\n'))),

        ('a', 'a({},{})'.format(1, ord('\0'))),
        ('a\n', 'a({},{})'.format(1, ord('\n'))),
        ('a \n', 'a({},{})'.format(1, ord(' '))),
        (' a \n', 'a({},{})'.format(1, ord(' '))),
        ('a\nbc', 'a({},{})'.format(1, ord('\n'))),

        ('thing', 'thing({},{})'.format(5, ord('\0'))),
        ('thing\n', 'thing({},{})'.format(5, ord('\n'))),
        (' thing\n', 'thing({},{})'.format(5, ord('\n'))),
        ('\tthing\n', 'thing({},{})'.format(5, ord('\n'))),
        ('\tthing', 'thing({},{})'.format(5, ord('\0'))),
        ('thing foo bar', 'thing({},{})'.format(5, ord(' ')))
    ]

    for (i, o) in cases:
        tcount += 1
        checker = expect_stdout_to_be(o)
        fcount += test_case('repl_word_test', checker=checker, stdin=i)

    for (i, _) in cases:
        tcount += 1
        checker = expect_status_to_be(0)
        fcount += test_case('repl_word_test', checker=checker, stdin=i)

    return (tcount, fcount)

def display_stack_test():
    (tcount, fcount) = (0, 0)

    cases = [
        [1, 2, 3],
        [3, 2, 1],
        [2, 1, 3],
        [-17, 30, 0],
        [2, 3212, 11],
        [-232, -232, -12]
    ]

    for args in cases:
        tcount += 1

        rargs = reversed(args)
        l = len(args)
        o1 = ' '.join([str(i) for i in args])
        o2 = ' '.join([str(i) for i in rargs])
        expected = '[{}] {} \n{}'.format(l, o1, o2)

        checker = expect_stdout_to_be(expected)
        fcount += test_case('display_stack_test', checker=checker, args=args)

    for args in cases:
        tcount += 1
        checker = expect_status_to_be(0)
        fcount += test_case('display_stack_test', checker=checker, args=args)

    return (tcount, fcount)

def to_r_test():
    (tcount, fcount) = (0, 0)

    cases = [[1, 2], [-1, -2], [17, -256], [0, 0], [24, -56], [-23, -19]]

    for args in cases:
        tcount += 1
        expected = ' '.join([str(i) for i in args])
        checker = expect_stdout_to_be(expected)
        fcount += test_case('to_r_test', checker=checker, args=args)

    return (tcount, fcount)

def r_from_test():
    (tcount, fcount) = (0, 0)

    cases = [
        [1, 2, 3], [-1, -2, -3], [0, 0, 0], [10, 10, 10], [-34, 12, 17],
        [3434, 121, -234], [-223, -657, -1223], [0, 23, -567]
    ]

    for args in cases:
        tcount += 1
        expected = ' '.join([str(i) for i in args])
        checker = expect_stdout_to_be(expected)
        fcount += test_case('r_from_test', checker=checker, args=args)

    for args in cases:
        tcount += 1
        checker = expect_status_to_be(0)
        fcount += test_case('r_from_test', checker=checker, args=args)

    return (tcount, fcount)

def r_fetch_test():
    (tcount, fcount) = (0, 0)

    cases = [[1, 2], [0, 0], [-1, -2], [10, 234], [-11, -17], [80, 67]]

    for args in cases:
        tcount += 1
        (_, arg1) = args
        rargs = reversed(args)
        o1 = ' '.join([str(i) for i in [arg1] * 3])
        o2 = ' '.join([str(i) for i in rargs])
        expected = '{}\n{}'.format(o1, o2)
        checker = expect_stdout_to_be(expected)
        fcount += test_case('r_fetch_test', checker=checker, args=args)

    for args in cases:
        tcount += 1
        checker = expect_status_to_be(0)
        fcount += test_case('r_fetch_test', checker=checker, args=args)

    return (tcount, fcount)

def fetch_test():
    (tcount, fcount) = (0, 0)

    numbers = [0, -1, -10, 10, 28, -64, 128, -343, 123456789, -123456789]

    for n in numbers:
        tcount += 1
        checker = expect_stdout_to_be(repr(n))
        fcount += test_case('fetch_test', checker=checker, args=[n])

    return (tcount, fcount)

def store_test():
    (tcount, fcount) = (0, 0)

    numbers = [0, -1, -10, 10, 28, -64, 128, -343, 123456789, -123456789]

    for n in numbers:
        tcount += 1
        checker = expect_stdout_to_be(repr(n))
        fcount += test_case('store_test', checker=checker, args=[n])

    return (tcount, fcount)

def c_fetch_test():
    (tcount, fcount) = (0, 0)

    strings = ['foo', 'bar', 'baz', 'FOO', 'BAR', 'BAZ', ' ', '@#$!%',
               '123', '-1', '+-/*']

    for s in strings:
        tcount += 1
        checker = expect_status_to_be(ord(s[0]))
        args = [repr(s)]
        fcount += test_case('c_fetch_test', checker=checker, args=args)

    for s in strings:
        tcount += 1
        checker = expect_stdout_to_be(s)
        args = [repr(s)]
        fcount += test_case('c_fetch_test', checker=checker, args=args)

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
    'prints': prints_test,
    'printe': printe_test,
    'cfa': cfa_test,
    'gotz': gotz_test,
    'docolon': docolon_test,
    'execute': execute_test,
    'dot': dot_test,
    'sub': sub_test,
    'repl_word': repl_word_test,
    'display_stack': display_stack_test,
    'to_r': to_r_test,
    'r_from': r_from_test,
    'r_fetch': r_fetch_test,
    'fetch': fetch_test,
    'store': store_test,
    'c_fetch': c_fetch_test
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
