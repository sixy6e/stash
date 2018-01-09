#!/usr/bin/env python

"""
Run TaskB, which depends on TaskA, but don't feed all the params
required for TaskA, but parse them via the luigi.cfg.

Call:
luigi --module luigi_cfg_params TaskB --param-a "True" --param-b "False" --local-scheduler
"""

import luigi
from luigi.util import inherits, requires

class TaskA(luigi.Task):

    param_a = luigi.Parameter()
    param_b = luigi.Parameter()
    param_c = luigi.Parameter() # define the value in the luigi.cfg
    param_d = luigi.Parameter() # define the value in the luigi.cfg
    param_e = luigi.Parameter(default=None) # define the value in the luigi.cfg

    def output(self):
        return luigi.LocalTarget('TaskA.txt')

    def run(self):
        with self.output().open('w') as src:
            print("TaskA's param_a: ", self.param_a)
            src.write("TaskA's param_a: {}".format(self.param_a))
            print("TaskA's param_b: ", self.param_b)
            src.write("TaskA's param_b: {}".format(self.param_b))
            print("TaskA's param_c: ", self.param_c)
            src.write("TaskA's param_c: {}".format(self.param_c))
            print("TaskA's param_d: ", self.param_d)
            src.write("TaskA's param_d: {}".format(self.param_d))
            print("TaskA's param_e: ", type(self.param_e))
            src.write("TaskA's param_e: {}".format(type(self.param_e)))


# uncommenting inherits will demonstrate failure in parameters not being set
# @inherits(TaskA)
class TaskB(luigi.Task):

    param_a = luigi.Parameter()
    param_b = luigi.Parameter()

    def requires(self):
        # note we aren't parsing params c & d, but they're declared in lugi.cfg
        return TaskA(self.param_a, self.param_b)

    def output(self):
        return luigi.LocalTarget('TaskB.txt')

    def run(self):
        with self.output().open('w') as src:
            print("TaskB's param_a: ", self.param_a)
            print("TaskB's param_b: ", self.param_b)
            src.write("TaskB's param_a: {}".format(self.param_a))
            src.write("TaskB's param_b: {}".format(self.param_b))


if __name__ == '__main__':
    luigi.run()
