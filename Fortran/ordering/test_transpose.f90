SUBROUTINE ordering(in_array, ncol, nrow, out_array)
    INTEGER*8 ncol, nrow
    INTEGER*2 in_array(ncol, nrow)
    INTEGER*2 out_array(ncol, nrow)
!f2py integer intent(hide), depend(in_array) :: nrow=shape(in_array,1), ncol=shape(in_array,0)
!f2py intent(out) out_array

    print*, 'fortran'
    print*, 'in_array'
    print*, 'ncol: ', ncol
    print*, 'nrow: ', nrow
    print*, 'size(in_array, 1)'
    print*, size(in_array, 1)
    print*, 'size(in_array, 2)'
    print*, size(in_array, 2)
    out_array = in_array * 2
    print*, 'out_array'
    print*, 'size(out_array, 1)'
    print*, size(out_array, 1)
    print*, 'size(out_array, 2)'
    print*, size(out_array, 2)

    print*, 'in_array'
    print*, in_array
    print*, 'out_array'
    print*, out_array
    
END SUBROUTINE ordering
