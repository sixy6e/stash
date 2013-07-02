MODULE test
    IMPLICIT NONE
CONTAINS

    SUBROUTINE bool(a, length)
        IMPLICIT NONE
        INTEGER*8 :: length
        REAL*4, DIMENSION(length), INTENT(in) :: a
        !f2py depend(length), a

        INTEGER :: tf, i

        do i = 1, length
            tf = a(i) .lt. 6
            print*, a(i)
            print*, 'tf', tf
            print*, 'tf * tf', tf * tf
        enddo
    END SUBROUTINE bool
END MODULE test
