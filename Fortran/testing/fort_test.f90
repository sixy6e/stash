subroutine test_array(a, b, c)
    integer, intent(in) :: a(:,:)
    real, intent(inout) :: b(:,:)
    integer, intent(in) :: c
    !integer :: i, j, dim1=shape(a, 0), dim2=shape(a,1)
    integer :: i, j, dim1, dim2
    dim1 = size(a, 1)
    dim2 = size(a, 2)
    !real :: b(dim1,dim2)

    do i=1, dim1
        do j=1, dim2
            b(i,j) = a(i,j)*c
        enddo
    enddo

end subroutine test_array

