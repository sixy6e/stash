#!/usr/bin/env python

import os
from os.path import join as pjoin
import luigi
import cPickle as pickle


def my_function(argument):
    if argument % 2 == 0:
        return "Number is even"
    else:
        msg = "Number: {}; is odd and must be even."
        raise TypeError(msg.format(argument))


class WriteTask(luigi.Task):

    """Execute some task"""

    out_path = luigi.Parameter()
    factor = luigi.Parameter()

    def requires(self):
        return []

    def output(self):
        out_path = self.out_path
        target = pjoin(out_path, '{}_greeting.txt'.format(self.factor))
        return luigi.LocalTarget(target)

    def run(self):
        with self.output()[("I'm ", self.factor)].open('w') as src:
                src.write('Hello {}'.format(self.factor))


class Combine(luigi.Task):

    """Combine outputs."""

    out_path = luigi.Parameter()

    def requires(self):
        factors = ['John', 'Lucy', 'Chris']
        return {factor: WriteTask(self.out_path, factor) for factor in factors}

    def output(self):
        out_path = self.out_path
        target = pjoin(out_path, 'greetings.pkl')
        return luigi.LocalTarget(target)

    def run(self):
        data = {}
        for key in self.input():
            data[key] = self.input()[key].path

        with self.output().open('w') as src:
            pickle.dump(data, src)


if __name__ == '__main__':
    tasks = [Combine(os.getcwd())]
    luigi.build(tasks, local_scheduler=True, workers=1)
