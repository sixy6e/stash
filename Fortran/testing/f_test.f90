SUBROUTINE jadd(a, b, x, y)

    IMPLICIT NONE

    INTEGER :: x, y, i, j
    INTEGER, DIMENSION(:,:), INTENT(IN) :: a
    INTEGER, ALLOCATABLE, INTENT(OUT) :: b(:,:)

    allocate(b(x,y))

    do i = 1, x
        do j = 1, y
            b(j,i) = a(j,i)
        enddo
    enddo
END SUBROUTINE jadd
