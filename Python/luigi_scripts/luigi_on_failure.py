#!/usr/bin/env python

from os.path import join as pjoin
import traceback
import luigi
import numpy
import h5py

OUT_FNAME = 'test-luigi-fails.h5'
DSET_NAME = 'events'


def my_function(argument):
    if argument % 2 == 0:
        return "Number is even"
    else:
        msg = "Number: {}; is odd and must be even."
        raise TypeError(msg.format(argument))


class ExecuteTask(luigi.Task):

    """Execute some task"""

    out_path = luigi.Parameter()
    argument = luigi.Parameter()

    def requires(self):
        return []

    def output(self):
        out_path = self.out_path
        target = pjoin(out_path, 'ExecuteTask_{}.task')
        return luigi.LocalTarget(target.format(self.argument))

    def on_failure(self, exception):
        with h5py.File(OUT_FNAME) as fid:
            record = fid[DSET_NAME][self.argument]
            record['message'] = exception.message
            fid[DSET_NAME][self.argument] = record

        traceback_string = traceback.format_exc()
        return "Runtime error:\n%s" % traceback_string

    def run(self):
        result = my_function(self.argument)
        with self.output().open('w') as src:
            src.write('completed')


if __name__ == '__main__':
    dims = 20
    arguments = range(dims)
    dtype = numpy.dtype([('argument', numpy.int),
                         ('message', h5py.special_dtype(vlen=str))])
                         #('message', 'S100')])
    data = numpy.zeros(dims, dtype=dtype)
    data['argument'] = arguments
    data['message'] = ''
    with h5py.File(OUT_FNAME, 'w') as fid:
        fid.create_dataset(DSET_NAME, data=data, compression=4)

    tasks = [ExecuteTask('', arg) for arg in arguments]
    luigi.build(tasks, local_scheduler=True, workers=1)
