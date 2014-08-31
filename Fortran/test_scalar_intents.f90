subroutine t(a,b,c)
    implicit none
!    use sys_variables, only : pi, d2r, r2d
    double precision, intent(in) :: a
    double precision, intent(out) :: b
    integer, intent(out) :: c
    c = 0
    b = a + 1

end subroutine t    
