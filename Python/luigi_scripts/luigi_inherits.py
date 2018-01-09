#!/usr/bin/env python

import luigi
from luigi.util import inherits, requires


class TaskA(luigi.Task):

    param_a = luigi.Parameter()

    def output(self):
        return luigi.LocalTarget('TaskA.txt')

    def run(self):
        with self.output().open('w') as src:
            print("TaskA's param_a: ", self.param_a)
            src.write("TaskA's param_a: {}".format(self.param_a))

@inherits(TaskA)
class TaskB(luigi.Task):

    param_b = luigi.Parameter()

    def output(self):
        return luigi.LocalTarget('TaskB.txt')

    def run(self):
        with self.output().open('w') as src:
            print("TaskB's param_a: ", self.param_a)
            print("TaskB's param_b: ", self.param_b)
            src.write("TaskB's param_a: {}".format(self.param_a))
            src.write("TaskB's param_b: {}".format(self.param_b))

@inherits(TaskB)
class TaskC(luigi.Task):

    param_c = luigi.Parameter()

    def output(self):
        return luigi.LocalTarget('TaskC.txt')

    def run(self):
        print(self.deps())
        with self.output().open('w') as src:
            print("TaskC's param_a: ", self.param_a)
            print("TaskC's param_b: ", self.param_b)
            print("TaskC's param_c: ", self.param_c)
            src.write("TaskC's param_a: {}".format(self.param_a))
            src.write("TaskC's param_b: {}".format(self.param_b))
            src.write("TaskC's param_c: {}".format(self.param_c))


class Execute(luigi.WrapperTask):

    aa = luigi.Parameter()
    bb = luigi.Parameter()
    cc = luigi.Parameter()

    def requires(self):
        return {'taskc': TaskC(self.aa, self.bb, self.cc),
                'taskb': TaskB(self.aa, self.bb),
                'taska': TaskA(self.aa)}

if __name__ == '__main__':
    luigi.run()
