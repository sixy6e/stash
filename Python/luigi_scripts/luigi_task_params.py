#!/usr/bin/env python

import luigi


class TaskA(luigi.Task):

    p = luigi.TupleParameter(default=(3, 3))

    def output(self):
        return luigi.LocalTarget('tuple-result-A.txt')

    def run(self):
        with self.output().open('w') as src:
            src.write('rows: {}, cols: {}\n'.format(self.p[0], self.p[1]))
            src.write('npoints: {}'.format(self.p[0] * self.p[1]))


class TaskB(luigi.Task):

    p = luigi.TupleParameter(default=(5, 5))

    def output(self):
        return luigi.LocalTarget('tuple-result-B.txt')

    def run(self):
        with self.output().open('w') as src:
            src.write('rows: {}, cols: {}\n'.format(self.p[0], self.p[1]))
            src.write('npoints: {}'.format(self.p[0] * self.p[1]))

class Do(luigi.Task):

    task = luigi.TaskParameter()

    def requires(self):
        return self.task

    def output(self):
        return luigi.LocalTarget('Do-target-{}'.format(self.task.get_task_family()))

    def run(self):
        print('*'*50)
        print(self.task.get_task_family())
        print(self.deps())
        print('*'*50)
        fname = self.input().path
        with open(fname, 'r') as src:
            data = src.readlines()

        with self.output().open('w') as src:
            src.writelines(data)


class TaskRunV1(luigi.WrapperTask):

    def requires(self):
        return [TaskA(), TaskB()]


class TaskRunV2(luigi.WrapperTask):

    def requires(self):
        print('*'*50)
        print("Configuration")
        print(luigi.interface.core())
        print('*'*50)
        print('*'*50)
        print("Number of Workers")
        print(luigi.interface.core().workers)
        print('*'*50)
        return [Do(TaskA()), Do(TaskB())]


if __name__ == '__main__':
    luigi.run()
