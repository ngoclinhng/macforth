import subprocess
from subprocess import CalledProcessError, Popen, PIPE
from termcolor import colored

NASM = ['nasm', '-f', 'macho64', '-i', '../src/', '-d', 'TEST']
LD = ['ld', '-lSystem']

def test_case(name, checker, args=[], stdin=''):
    """Builds and runs the test case with the given name.

    Paramaters
    ----------
    name: str
        The name of the test case. It expects that a '.asm' file
        (will later be referenced as the test source file) with the
        exact same name must be present in the current directory.
    checker: callable[[args, stdin, stdout, status], bool]
        Is a callable which takes five arguments and return either `True`
        or `False`. The meaning of those five arguments are:
        - args: list of str
            The same as `args` argument passed into `test_case`.
        - stdin: str
            The same as `stdin` argument passed into `test_case`.
        - stdout: str
            The string that has been written to stdout when the test case
            finishes its execution.
        - status: int
            The exit status code of the test case process.
    args: list of str, optional
        During the compilation of the test source file, each macro of
        the form `ARG[X]` (where `X` is 0, 1, 2...) will be replaced by
        the corresponding value in the `args` list as is.
    stdin: str, optional
        If the test case needs to take input from stdin, you can supply to
        it via the `stdin` argument.
    """
    print('{}: '.format(name), end='')
    macros = ['-dARG{}={}'.format(i,v) for i, v in enumerate(args)]
    (ok, msg) = build_test_case(name, compiler_options=macros)

    if ok:
        (stdout, status) = run_test_case(name, stdin)
        (check_ok, check_msg) = checker(args, stdin, stdout, status)

        if check_ok:
            print(colored('PASSED', 'green'))
            print_args(args)
            print('  * stdin:  {}'.format(repr(stdin)))
            print('  * stdout: {}'.format(repr(stdout)))
            print('  * status: {}'.format(repr(status)))
            return 0
        else:
            print(colored('FAILED', 'red'))
            print(check_msg)
            print_args(args)
            print('  * stdin:  {}'.format(repr(stdin)))
            print('  * stdout: {}'.format(repr(stdout)))
            print('  * status: {}'.format(repr(status)))
            return 1
    else:
        print(colored('Failed to build executable', 'red'))
        print_args(args)
        print('  * stderr: {}'.format(colored(msg, 'yellow')))
        return 1

def expect_status_to_be(s):
    def checker(args, stdin, stdout, status):
        msg = ''
        if status == s:
            return (True, msg)
        else:
            msg = failed_msg('status', s, status)
            return (False, msg)
    return checker

def expect_stdout_to_be(s):
    def checker(args, stdin, stdout, status):
        msg = ''
        if stdout == s:
            return (True, msg)
        else:
            msg = failed_msg('stdout', s, stdout)
            return (False, msg)
    return checker

def expect(stdout='', status=0):
    def checker(args, stdin, t_stdout, t_status):
        msg = ''
        if stdout == t_stdout and status == t_status:
            return (True, msg)
        elif stdout != t_stdout:
            msg = failed_msg('stdout', stdout, t_stdout)
            return (False, msg)
        else:
            msg = failed_msg('status', status, t_status)
            return (False, msg)
    return checker

def failed_msg(name, expected, got):
    e = '  * Expected `{}` to be: '.format(name)
    e1 = '{}{}\n'.format(e, repr(expected))

    g = 'got: '.rjust(len(e))
    g1 = '{}{}'.format(g, repr(got))

    return colored(e1 + g1, 'yellow')

def build_test_case(name, compiler_options=[]):
    """Builds the executable with the given name"""
    (ok, msg) = nasm(name, options=compiler_options)
    if ok:
        # Dependencies for all test cases
        ld_sources = [target(name), target('utils')]
        return ld(name, sources=ld_sources)
    else:
        return (False, msg)

def run_test_case(name, stdin=''):
    """Spawns a new process and executes the executable with the given
    name.

    Paramaters
    ----------
    name: str
        The name of the executable to be executed. It is implicitly that
        the executable file is located at the relative path: 'bin/' + name
    stdin: str
        If the executable needs to take input from stdin, you can supply to
        it via this argument.

    Returns
    -------
    A tuple of two arguments `(stdout, status)`, in which:
    - `stdout` is what has been written to stdout when execution is done.
    - `status` is the process exit status code.
    """
    exe = './' + target(name, is_object=False)
    try:
        p = Popen([exe], shell=None, stdin=PIPE, stdout=PIPE, text=True)
        (output, error) = p.communicate(input=stdin)
        return (output, p.returncode)
    except CalledProcessError as exc:
        return (exc.output, exc.returncode)
    else:
        return ('', 0)

def print_args(args):
    print('  * args:')
    for i, v in enumerate(args):
        print('    ARG{}={}'.format(i, repr(v)))

def nasm(name, sources=[], options=[]):
    """
    Runs the nasm command to build the macho64 object file from the given
    `sources`.

    Paramaters
    ----------
    name: str
        The name of the target to be built (without the '.o' extension).
        The relative path to the final target is: 'obj/' + name + '.o'.
    sources: list of str
        The list of source files (default []). If no sources was specified,
        one single source file with the same name is implicitly in the
        current directory.
    options: list if str, optional
        Additional compile options, such as macros definitions, etc...

    Returns
    -------
    two elements tuple `(ok, msg)`:
       `ok` is `True` is the build succeeded, otherwise it is `False`.
        `msg` is empty string if the build succeeded, otherwise it is the
        error message that would have been written out to stderr.
    """
    target_file = target(name)
    source_files = sources

    if not sources:
        source_files = [name + '.asm']

    cmd = NASM + options + source_files + ['-o', target_file]
    ret = subprocess.run(cmd, stderr=PIPE, text=True)

    if ret.returncode != 0:
        return (False, ret.stderr)
    else:
        return (True, '')

def ld(name, sources = [], options = []):
    """Runs the ld command to link all object files in the given sources to
    produce the final executable file.

    Paramaters
    ----------
    name: str
        The name of the executable target to be built. The relative path
        to the final executable file is: 'bin/' + name.
    sources: list of str
        The list of all object files to which the target depends on. If
        no object files were specified, the target implicitly depends on
        a single object file with the same name in the relative path:
        'obj' + 'name' + '.o'
    options: list of str, optional
        A list of linker options.

    Returns
    -------
    two elements tuple `(ok, msg)`:
       `ok` is `True` is the build succeeded, otherwise it is `False`.
        `msg` is empty string if the build succeeded, otherwise it is the
        error message that would have been written out to stderr.
    """
    target_file = target(name, is_object=False)
    source_files = sources

    if not sources:
        source_files = [target(name)]

    cmd = LD + options + ['-o', target_file] + source_files
    ret = subprocess.run(cmd, stderr=PIPE, text=True)

    if ret.returncode != 0:
        return (False, ret.stderr)
    else:
        return (True, '')

def target(name, is_object=True):
    """Returns a relative path (relative to the current directory) to the
    target with the given `name`.

    If `is_object` is set to `True`, the target is an object file.
    Otherwise, it is an executable file.
    """
    if is_object:
        return 'obj/' + name + '.o'
    else:
        return 'bin/' + name
