MODULE prog
    IMPLICIT NONE
CONTAINS

    SUBROUTINE dot(m1, nr1, nc1, m2, nr2, nc2, mtx)
        !DOUBLE PRECISION, DIMENSION(nr1, nc1), INTENT(in) :: m1
        !DOUBLE PRECISION, DIMENSION(nr2, nc2), INTENT(in) :: m2
        !DOUBLE PRECISION, DIMENSION(nr1, nc2), INTENT(inout) :: mtx
        !INTEGER, INTENT(in) :: nr1, nc1, nr2, nc2
        REAL*4, INTENT(in) :: nr1, nc1, nr2, nc2
        REAL*4, DIMENSION(nr1, nc1), INTENT(in) :: m1
        REAL*4, DIMENSION(nr2, nc2), INTENT(in) :: m2
        REAL*4, DIMENSION(nr1, nc2), INTENT(inout) :: mtx
        !REAL*4, INTENT(in) :: nr1, nc1, nr2, nc2

!f2py   check(nc1==nr2) nr2

        DOUBLE PRECISION :: sum
        INTEGER :: i, j, k

        DO i = 1,nr1
            DO j = 1,nc2
                sum = 0.0
                DO k = 1, nc1
                    sum = sum + m1(i,k)*m2(k,j)
                END DO
                mtx(i,j) = sum
            END DO
        END DO

    END SUBROUTINE dot

END MODULE prog

