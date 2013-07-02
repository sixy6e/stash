MODULE idl_histogram
    IMPLICIT NONE

!    INTERFACE data_type
!       MODULE PROCEDURE histogram_int
!       MODULE PROCEDURE histogram_float
!    END INTERFACE data_type

CONTAINS

    !SUBROUTINE histogram_int(array, Max, Min, ri, hist)
    SUBROUTINE histogram_int(array, hist, a_sz, min_, max_, binsz)
    !SUBROUTINE histogram_int(array, hist, nbins, ri, a_sz, min_, max_)

       IMPLICIT NONE

       INTEGER :: a_sz
       INTEGER, DIMENSION(:), INTENT(IN) :: array
       !INTEGER, DIMENSION(a_sz), INTENT(IN) :: array
       !REAL, OPTIONAL, INTENT(IN) :: Max
       !REAL, OPTIONAL, INTENT(IN) :: Min

       !INTEGER :: nbins
       INTEGER, DIMENSION(:), INTENT(INOUT) :: hist
       !INTEGER, DIMENSION(nbins), INTENT(INOUT) :: hist
       !INTEGER, OPTIONAL, DIMENSION(:), INTENT(OUT) :: ri
       !INTEGER, DIMENSION(:), INTENT(INOUT) :: ri
       !INTEGER, DIMENSION(ri_sz), INTENT(INOUT) :: ri
       !INTEGER, DIMENSION(:), ALLOCATABLE, INTENT(OUT) :: ri

       !INTEGER :: i, a_sz
       INTEGER :: i
       INTEGER :: min_, max_, y, ind
       REAL*8 :: binsz
       !LOGICAL (KIND=1) :: l
       INTEGER*4 :: l

       !bool test
       i = 10
       l = abs(i .eq. 10)
       print*, 'true l', l
       l = l * 234
       print*, 'l * 234', l 
       l = abs(i .eq. 9)
       print*, 'false l', l
       l = l * 234
       print*, 'l * 234', l
       print*, 'min', min_
       print*, 'max', max_

       print*, '1st hist loop'
       ! need to check that the value of array(i) is le max
       do i = 1, a_sz
          !y = abs(array(i) .le. max_)
          y = abs((array(i) .le. max_) .and. (array(i) .ge. min_))
          !print*, 'y', y
          !ind = 1 + floor((y * (array(i) - min_)) / binsz) + 1
          ind = 1 + ((floor((array(i) - min_) / binsz) + 1) * y)
          !print*, 'a(i)', array(i)
          !print*, 'ind', ind
          !hist(array(i) + min_) = hist(array(i) + min_) + 1
          hist(ind) = hist(ind) + y
       enddo

       !IF (PRESENT(Max)) THEN
       !   max_ = Max
       !ELSE
       !   max_ = MAXVAL(array)
       !END IF

       !IF (PRESENT(Min)) THEN
       !   min_ = Min
       !ELSE
       !   min_ = MINVAL(array)
       !END IF

       !IF (PRESENT(ri)) THEN

       !   nbins = (max_ - min_) + 1
       !   n = SIZE(array)
       !   ALLOCATE(hist(nbins))
       !   ri_sz = nbins + n + 1
       !   ALLOCATE(ri(ri_sz))

       !   do i = 1, n
       !      hist(array(i)) = hist(array(i)) + 1
       !   enddo

       !   ri(1) = nbins + 1

       !  do i=1, nbins
       !      ri(i+1) = ri(i) + hist(i)
       !      hist(i) = 0
       !   enddo

          !hist = 0

       !   do i = 1, n
       !      hist(array(i)) = hist(array(i)) + 1
       !      ri(ri(array(i)) - 1 + hist(array(i))) = i - 1
       !   enddo
       !ELSE
       !   nbins = (max_ - min_) + 1
       !   n = SIZE(array)
       !   ALLOCATE(hist(nbins))

       !   do i = 1, n
       !      hist(array(i)) = hist(array(i)) + 1
       !   enddo
       !END IF

    END SUBROUTINE histogram_int

    !SUBROUTINE reverse_indices_int(array, histo, ri, nbins, a_sz, ri_sz, min_, max_, binsz)
    SUBROUTINE reverse_indices_int(array, ri, histo, nbins, a_sz, ri_sz, min_, max_, binsz)
       IMPLICIT NONE

       !INTEGER :: a_sz
       INTEGER, DIMENSION(:), INTENT(IN) :: array
       !REAL, OPTIONAL, INTENT(IN) :: Max
       !REAL, OPTIONAL, INTENT(IN) :: Min
       INTEGER, DIMENSION(:), INTENT(IN) :: histo

       !INTEGER :: nbins
       INTEGER, DIMENSION(nbins+1) :: hist
       !INTEGER, DIMENSION(nbins), INTENT(IN) :: histo
       !INTEGER, DIMENSION(nbins), INTENT(INOUT) :: hist
       !INTEGER, OPTIONAL, DIMENSION(:), INTENT(OUT) :: ri
       !INTEGER, DIMENSION(:), INTENT(INOUT) :: ri
       !INTEGER :: ri_sz
       INTEGER, DIMENSION(:), INTENT(INOUT) :: ri
       !INTEGER, DIMENSION(:), INTENT(INOUT) :: ri
       !INTEGER, DIMENSION(:), ALLOCATABLE, INTENT(OUT) :: ri

       INTEGER :: nbins, i, n, ri_sz, a_sz
       !INTEGER :: i, n, ri_sz
       !INTEGER :: i, n, nbins 
       INTEGER :: min_, max_, y, ind
       REAL*8 :: binsz
       !LOGICAL (KIND=1) :: l

       print*, 'hist(1)', hist(1)
       print*, 'hist(2)', hist(2)
       hist = 0
       print*, 'hist(1)', hist(1)
       print*, 'hist(2)', hist(2)

       !do i = 1, a_sz
       !   y = abs((array(i) .le. max_) .and. (array(i) .ge. min_))
          !print*, 'y', y
          !ind = 1 + int((y * (array(i) + 1 - min_)) / binsz)
          !ind = 1 + floor((y * (array(i) - min_)) / binsz) + 1
       !   ind = 1 + ((floor((array(i) - min_) / binsz) + 1) * y)
          !print*, 'ind', ind
          !hist(array(i) + min_) = hist(array(i) + min_) + 1
       !   hist(ind) = hist(ind) + y
       !enddo

       ri(2) = nbins + 1
       hist(1) = 0

       print*, 'ri(1)', ri(1)
       print*, 'ri(0)', ri(0)
       !ri(1) = nbins
       print*, 'nbins', nbins

       do n = 2, nbins + 1
          !print*, 'n', n
          !print*, 'ri(n)', ri(n)
          !print*, 'hist(n)', hist
          ri(n+1) = ri(n) + histo(n-1)
       enddo

       hist = 0

       do i = 1, a_sz
          !y = (abs(array(i) .le. max_)) .and. (abs(array(i) .ge. min_))
          y = abs((array(i) .le. max_) .and. (array(i) .ge. min_))
          !ind = 1 + int((y * (array(i) + 1 - min_)) / binsz)
          !ind = 1 + floor((y * (array(i) - min_)) / binsz) + 1
          ind = 1 + ((floor((array(i) - min_) / binsz) + 1) * y)
          !print*, 'y', y
          !print*, 'ind', ind
          !hist(array(i) + min_) = hist(array(i) + min_) + 1
          hist(ind) = hist(ind) + y
          !print*, 'hist ok'
          !ri(ri(array(i)) - 1 + hist(array(i))) = i - 1
          !ri(ri(array(i)) + hist(array(i))) = i - 1
          !print*, 'ind, i-1, hist(ind), ri(ind)', ind, i - 1, hist(ind), ri(ind)
          ri(ri(ind) + hist(ind) + 1) = i - 1
          ri(1) = 1
          hist(1) = 0
          ri(2) = nbins + 1
          !print*, 'ri ok'
       enddo

       print*, 'ri(1)', ri(1)
       print*, 'ri(0)', ri(0)

    END SUBROUTINE reverse_indices_int

END MODULE idl_histogram

