import sys
from pathlib import Path
from testhelper import nasm, test_case
from testhelper import expect_status_to_be, expect_stdout_to_be, expect
from termcolor import colored
from functools import reduce
from string import printable
import random

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
# TEST SUITES.
#

def init_test():
    checker = expect_status_to_be(0)
    fcount = test_case('INIT_test', checker=checker)
    return (1, fcount)

def key_test():
    (tcount, fcount) = (0, 0)

    inputs = ['', ':', ' ', 'SQUARE', 'DUP', '*', ';', 'FOO', 'BAR']

    for i in inputs:
        tcount += 1
        checker = expect_status_to_be(0 if i == '' else ord(i[0]))
        fcount += test_case('KEY_test', checker=checker, stdin=i)

    return (tcount, fcount)

def emit_test():
    (tcount, fcount) = (0, 0)

    # Printable chars
    l1 = [(hex(ord(c)), '\n' if c == '\r' else c) for c in printable]

    # Least significant byte
    l2 = [
        ('0x30', '0'),
        ('0x3031', '1'),
        ('0x303132', '2'),
        ('0x30313233', '3'),
        ('0x3031323334', '4'),
        ('0x303132333435', '5'),
        ('0x30313233343536', '6'),
        ('0x3031323334353637', '7'),
        ('0x303132333435363738', '8'),
    ]

    cases = l1 + l2

    for (i, o) in cases:
        tcount += 1
        checker = expect(stdout=o, status=0)
        fcount += test_case('EMIT_test', checker=checker, args=[i])

    return (tcount, fcount)

def u_dot_test():
    (tcount, fcount) = (0, 0)

    # Convert an 8-byte integer to unsigned.
    to_u = lambda n : n & 0xffffffffffffffff

    numbers = list(range(0, 10)) + [10, 11, 123, 8106, -123, -1]
    base2 = [(n, 2, bin(to_u(n))) for n in numbers]
    base8 = [(n, 8, oct(to_u(n))) for n in numbers]
    base10 = [(n, 10, repr(to_u(n))) for n in numbers]
    base16 = [(n, 16, '0x{:X}'.format(to_u(n))) for n in numbers]
    cases = base10 + base16 + base2 + base8

    for (n, b, o) in cases:
        tcount += 1
        args = [n, b]
        checker = expect(stdout=o, status=0)
        fcount += test_case('U_DOT_test', checker=checker, args=args)

    return (tcount, fcount)

def dot_test():
    (tcount, fcount) = (0, 0)

    numbers = list(range(0, 10)) + [10, 11, 123, 8106, -123, -1, -2, -48]
    base2 = [(n, 2, bin(n)) for n in numbers]
    base8 = [(n, 8, oct(n)) for n in numbers]
    base10 = [(n, 10, repr(n)) for n in numbers]
    base16 = [(n, 16, hex(n).upper().replace('X', 'x')) for n in numbers]
    cases = base10 + base16 + base2 + base8

    for (n, b, o) in cases:
        tcount += 1
        args = [n, b]
        checker = expect(stdout=o, status=0)
        fcount += test_case('DOT_test', checker=checker, args=args)

    return (tcount, fcount)

def to_cfa_test():
    (tcount, fcount) = (0, 0)

    words = ['INIT', 'TO_CFA', 'DOT', 'EXIT', 'KEY', 'EMIT', 'STATE',
             'BASE', 'U_DOT', 'PUSH_HFA', 'CHAO']

    for w in words:
        tcount += 1
        checker = expect_status_to_be(0)
        fcount += test_case('TO_CFA_test', checker=checker, args=[w])

    return (tcount, fcount)

def parse_name_test():
    (tcount, fcount) = (0, 0)

    inputs = [
        ('', ''),
        (' ', ''),

        ('foo', 'foo'),
        ('foo ', 'foo'),
        ('foo bar', 'foo'),
        ('foo\nbar', 'foo'),
        ('foo\tbar', 'foo'),
        ('foo bar\n', 'foo'),

        (' foo', 'foo'),
        ('\nfoo', 'foo'),
        ('\tfoo', 'foo'),

        ('fo\o', 'fo\o'),
        ('foo\ ', 'foo\\'),
        ('foo\ bar baz\n', 'foo\\'),

        ('1 2 3', '1'),
        ('123 foo bar', '123'),
        ('-123', '-123'),
        ('- 123', '-'),
        ('CREATE FOO FOO', 'CREATE')
    ]

    for (i, o) in inputs:
        tcount += 1
        checker = expect(stdout=o, status=len(o))
        fcount += test_case('PARSE_NAME_test', checker=checker, stdin=i)

    return (tcount, fcount)

def find_name_test():
    (tcount, fcount) = (0, 0)

    cases = [
        ('KEY', 'KEY', 'found', 0),
        ('key', 'KEY', 'found', 0),
        ('kEY', 'KEY', 'found', 0),
        ('kEy', 'KEY', 'found', 0),
        ('KeY', 'KEY', 'found', 0),
        ('Key', 'KEY', 'found', 0),

        ('PARSE-NAME', 'PARSE_NAME', 'found', 0),
        ('parse-name', 'PARSE_NAME', 'found', 0),
        ('PARSE-name', 'PARSE_NAME', 'found', 0),
        ('parse-NAME', 'PARSE_NAME', 'found', 0),
        ('Parse-Name', 'PARSE_NAME', 'found', 0),

        ('FIND-NAME', 'FIND_NAME', 'found', 0),
        ('find-name', 'FIND_NAME', 'found', 0),
        ('FInd-NamE', 'FIND_NAME', 'found', 0),

        ('EMIT', 'EMIT', 'found', 0),
        ('emit', 'EMIT', 'found', 0),
        ('eMIT', 'EMIT', 'found', 0),

        ('U.', 'U_DOT', 'found', 0),
        ('u.', 'U_DOT', 'found', 0),
        ('.', 'DOT', 'found', 0),

        ('EXIT', 'EXIT', 'found', 0),
        ('exit', 'EXIT', 'found', 0),
        ('EXit', 'EXIT', 'found', 0),

        ('>CFA', 'TO_CFA', 'found', 0),
        ('>cfa', 'TO_CFA', 'found', 0),
        ('>cFa', 'TO_CFA', 'found', 0),

        ('STATE', 'STATE', 'found', 0),
        ('state', 'STATE', 'found', 0),
        ('StaTe', 'STATE', 'found', 0),

        ('BASE', 'BASE', 'found', 0),
        ('base', 'BASE', 'found', 0),
        ('bASe', 'BASE', 'found', 0),

        ('BAR', 'BAR', 'found', 0),
        ('bar', 'BAR', 'found', 0),

        ('FOO', 'FOO', 'not_found', 0),
        ('foo', 'FOO', 'not_found', 0),
        ('BAZ', 'BAZ', 'not_found', 0),
        ('baz', 'BAZ', 'not_found', 0),

        ('INIT', 'INIT', 'not_found', 0),
        ('init', 'INIT', 'not_found', 0),

        ('THING', None, 'not_found', 0),
        ('thing', None, 'not_found', 0)
    ]

    for (name, label, stdout, status) in cases:
        tcount += 1
        args = [repr(name), label] if label else [repr(name)]
        checker = expect(stdout=stdout, status=status)
        fcount += test_case('FIND_NAME_test', checker=checker, args=args)

    return (tcount, fcount)

def execute_test():
    (tcount, fcount) = (0, 0)

    messages = ['Hello', 'hi', 'hey', 'hello, world!', '1', '-123']

    for msg in messages:
        tcount += 1
        checker = expect(stdout=msg, status=len(msg))
        args = [repr(msg), len(msg)]
        fcount += test_case('EXECUTE_test', checker=checker, args=args)

    return (tcount, fcount)

def latest_test():
    checker = expect_status_to_be(0)
    fcount = test_case('LATEST_test', checker=checker)
    return (1, fcount)

def create_test():
    (tcount, fcount) = (0, 0)

    cases = [
        ('X X', 'X'),
        ('X x', 'X'),
        ('X\nX', 'X'),
        ('X\nx', 'X'),

        ('FOO FOO', 'FOO'),
        ('FOO foo', 'FOO'),
        ('FOO\nFOO', 'FOO'),
        ('FOO\nfoo', 'FOO')
    ]

    for (i, o) in cases:
        tcount += 1
        checker = expect(stdout=o, status=8)
        a = [len(o)]
        fcount += test_case('CREATE_test', checker=checker, stdin=i, args=a)

    return (tcount, fcount)

def type_test():
    (tcount, fcount) = (0, 0)

    strings = ['', '1', 'a', 'A', 'foo', 'FOO', 'Hello, World!']

    for s in strings:
        tcount += 1
        checker = expect(stdout=s, status=len(s))
        args = [repr(s)]
        fcount += test_case('TYPE_test', checker=checker, args= args)

    return (tcount, fcount)

TEST_SUITES = {
    'init': init_test,
    'key': key_test,
    'emit': emit_test,
    'u_dot': u_dot_test,
    'dot': dot_test,
    'to_cfa': to_cfa_test,
    'parse_name': parse_name_test,
    'find_name': find_name_test,
    'execute': execute_test,
    'latest': latest_test,
    'create': create_test,
    'type': type_test
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
