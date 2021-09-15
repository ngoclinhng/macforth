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

TEST_SUITES = {
    'init': init_test,
    'next': next_test,
    'find': find_test
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
