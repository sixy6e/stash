#!/usr/bin/env python

import os
from os.path import join as pjoin
import luigi


def my_function(argument):
    if argument % 2 == 0:
        return "Number is even"
    else:
        msg = "Number: {}; is odd and must be even."
        raise TypeError(msg.format(argument))


class WriteTask(luigi.Task):

    """Execute some task"""

    out_path = luigi.Parameter()

    def requires(self):
        return []

    def output(self):
        out_path = self.out_path
        target1 = pjoin(out_path, 'data1.txt')
        target2 = pjoin(out_path, 'data2.txt')
        return {'a': luigi.LocalTarget(target1),
                'b': luigi.LocalTarget(target2)}

    def run(self):
        with self.output()['a'].open('w') as src1:
            with self.output()['b'].open('w') as src2:
                src1.write('Hello')
                src2.write('World')


class Combine(luigi.Task):

    """Combine outputs."""

    out_path = luigi.Parameter()

    def requires(self):
        return WriteTask(self.out_path)

    def output(self):
        out_path = self.out_path
        target = pjoin(out_path, 'data-combine.txt')
        return luigi.LocalTarget(target)

    def run(self):
        with self.input()['a'].open('r') as src1:
            with self.input()['b'].open('r') as src2:
                data1 = src1.readline()
                data2 = src2.readline()

        with self.output().open('w') as src:
            src.write(data1 + data2)


if __name__ == '__main__':
    tasks = [Combine(os.getcwd())]
    luigi.build(tasks, local_scheduler=True, workers=1)
