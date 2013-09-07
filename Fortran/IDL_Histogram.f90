MODULE idl_histogram
    IMPLICIT NONE
    ! Author: Josh Sixsmith, joshua.sixsmith@ga.gov.au
    !
    ! Copyright
    !
    ! Copyright (c) 2013, Josh Sixsmith
    ! All rights reserved.

    ! Redistribution and use in source and binary forms, with or without
    ! modification, are permitted provided that the following conditions are met:

    ! 1. Redistributions of source code must retain the above copyright notice, this
    !    list of conditions and the following disclaimer. 
    ! 2. Redistributions in binary form must reproduce the above copyright notice,
    !    this list of conditions and the following disclaimer in the documentation
    !    and/or other materials provided with the distribution. 

    ! THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
    ! ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
    ! WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
    ! DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
    ! ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
    ! (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    ! LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
    ! ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
    ! (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
    ! SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

    ! The views and conclusions contained in the software and documentation are those
    ! of the authors and should not be interpreted as representing official policies, 
    ! either expressed or implied, of the FreeBSD Project.
    !

CONTAINS

    SUBROUTINE histogram_int(array, hist, a_sz, nbins, min_, max_, max_bin, binsz)
       IMPLICIT NONE

       INTEGER*8 :: i, a_sz, y, ind, nbins
       INTEGER*2, DIMENSION(a_sz), INTENT(IN) :: array
       !f2py depend(a_sz), array
       INTEGER*4, DIMENSION(nbins), INTENT(INOUT) :: hist
       !f2py depend(nbins), hist

       INTEGER*2 :: min_, max_
       REAL*8 :: binsz, max_bin
       INTEGER :: tf

       ! need to check that the value of array(i) is le max
       do i = 1, a_sz
          tf = (array(i) .le. max_) .and. (array(i) .ge. min_) .and. (array(i) .lt. max_bin)
          y = tf * tf
          ind = 1 + ((floor((array(i) - min_) / binsz) + 1) * y)
          hist(ind) = hist(ind) + y
       enddo


    END SUBROUTINE histogram_int

    SUBROUTINE histogram_long(array, hist, a_sz, nbins, min_, max_, max_bin, binsz)

       IMPLICIT NONE

       INTEGER*8 :: i, a_sz, y, ind, nbins
       INTEGER*4, DIMENSION(a_sz), INTENT(IN) :: array
       !f2py depend(a_sz), array

       INTEGER*4, DIMENSION(nbins), INTENT(INOUT) :: hist
       !f2py depend(nbins), hist

       INTEGER*4 :: min_, max_
       REAL*8 :: binsz, max_bin
       INTEGER :: tf

       ! need to check that the value of array(i) is le max
       do i = 1, a_sz
          tf = (array(i) .le. max_) .and. (array(i) .ge. min_) .and. (array(i) .lt. max_bin)
          y = tf * tf
          ind = 1 + ((floor((array(i) - min_) / binsz) + 1) * y)
          hist(ind) = hist(ind) + y
       enddo


    END SUBROUTINE histogram_long

    SUBROUTINE histogram_dlong(array, hist, a_sz, nbins, min_, max_, max_bin, binsz)

       IMPLICIT NONE

       INTEGER*8 :: i, a_sz, y, ind, nbins
       INTEGER*8, DIMENSION(a_sz), INTENT(IN) :: array
       !f2py depend(a_sz), array

       INTEGER*4, DIMENSION(nbins), INTENT(INOUT) :: hist
       !f2py depend(nbins), hist

       INTEGER*8 :: min_, max_
       REAL*8 :: binsz, max_bin
       INTEGER :: tf

       ! need to check that the value of array(i) is le max
       do i = 1, a_sz
          tf = (array(i) .le. max_) .and. (array(i) .ge. min_) .and. (array(i) .lt. max_bin)
          y = tf
          ind = 1 + ((floor((array(i) - min_) / binsz) + 1) * y)
          hist(ind) = hist(ind) + y
       enddo


    END SUBROUTINE histogram_dlong

    SUBROUTINE histogram_float(array, hist, a_sz, nbins, min_, max_, max_bin, binsz)

       IMPLICIT NONE

       INTEGER*8 :: i, a_sz, y, ind, nbins
       REAL*4, DIMENSION(a_sz), INTENT(IN) :: array
       !f2py depend(a_sz), array

       INTEGER*4, DIMENSION(nbins), INTENT(INOUT) :: hist
       !f2py depend(nbins), hist

       REAL*4 :: min_, max_
       REAL*8 :: binsz, max_bin
       INTEGER :: tf

       ! need to check that the value of array(i) is le max
       do i = 1, a_sz
          tf = (array(i) .le. max_) .and. (array(i) .ge. min_) .and. (array(i) .lt. max_bin)
          y = tf * tf
          ind = 1 + ((floor((array(i) - min_) / binsz) + 1) * y)
          hist(ind) = hist(ind) + y
       enddo


    END SUBROUTINE histogram_float

    SUBROUTINE histogram_dfloat(array, hist, a_sz, nbins, min_, max_, max_bin, binsz)

       IMPLICIT NONE

       INTEGER*8 :: i, a_sz, y, ind, nbins
       REAL*8, DIMENSION(a_sz), INTENT(IN) :: array
       !f2py depend(a_sz), array

       INTEGER*4, DIMENSION(nbins), INTENT(INOUT) :: hist
       !f2py depend(nbins), hist

       REAL*8 :: min_, max_
       REAL*8 :: binsz, max_bin
       INTEGER :: tf

       ! need to check that the value of array(i) is le max
       do i = 1, a_sz
          tf = (array(i) .lt. max_bin) .and. (array(i) .ge. min_) .and. (array(i) .le. max_)
          y = tf * tf
          ind = 1 + ((floor((array(i) - min_) / binsz) + 1) * y)
          hist(ind) = hist(ind) + y
       enddo


    END SUBROUTINE histogram_dfloat

    SUBROUTINE reverse_indices_int(array, hist, ri, nbins, a_sz, ri_sz, min_, max_, max_bin, binsz)
       IMPLICIT NONE

       INTEGER*8 :: i, n, ri_sz, a_sz, y, ind, nbins
       INTEGER*2, DIMENSION(a_sz), INTENT(IN) :: array
       !f2py depend(a_sz), array

       INTEGER*4, DIMENSION(nbins), INTENT(INOUT):: hist
       !f2py depend(nbins), hist

       INTEGER*4, DIMENSION(ri_sz), INTENT(INOUT) :: ri
       !f2py depend(ri_sz), ri

       INTEGER*4 :: min_, max_
       REAL*8 :: binsz, max_bin
       INTEGER :: tf

       ri(2) = nbins
       hist(1) = 0

       !print*, 'compute ivec'

       do n = 2, nbins
          ri(n+1) = ri(n) + hist(n)
       enddo

       hist = 0

       !print*, 'compute ovec'

       do i = 1, a_sz
          tf = (array(i) .lt. max_bin) .and. (array(i) .ge. min_) .and. (array(i) .le. max_)
          y = tf * tf
          ind = 1 + ((floor((array(i) - min_) / binsz) + 1) * y)
          hist(ind) = hist(ind) + y
          ri(ri(ind) + hist(ind) + 1) = i - 1
          ri(1) = 1
          hist(1) = 0
          ri(2) = nbins
       enddo

    END SUBROUTINE reverse_indices_int

    SUBROUTINE reverse_indices_long(array, hist, ri, nbins, a_sz, ri_sz, min_, max_, max_bin, binsz)
       IMPLICIT NONE

       INTEGER*8 :: i, n, ri_sz, a_sz, y, ind, nbins
       INTEGER*4, DIMENSION(a_sz), INTENT(IN) :: array
       !f2py depend(a_sz), array

       INTEGER*4, DIMENSION(nbins), INTENT(INOUT) :: hist
       !f2py depend(nbins), hist

       INTEGER*4, DIMENSION(ri_sz), INTENT(INOUT) :: ri
       !f2py depend(ri_sz), ri

       INTEGER*4 :: min_, max_
       REAL*8 :: binsz, max_bin
       INTEGER :: tf

       ri(2) = nbins
       hist(1) = 0

       !print*, 'compute ivec'
       do n = 2, nbins
          ri(n+1) = ri(n) + hist(n)
       enddo

       hist = 0

       !print*, 'compute ovec'
       do i = 1, a_sz
          tf = (array(i) .lt. max_bin) .and. (array(i) .ge. min_) .and. (array(i) .le. max_)
          y = tf * tf
          ind = 1 + ((floor((array(i) - min_) / binsz) + 1) * y)
          hist(ind) = hist(ind) + y
          ri(ri(ind) + hist(ind) + 1) = i - 1
          ri(1) = 1
          hist(1) = 0
          ri(2) = nbins
       enddo


    END SUBROUTINE reverse_indices_long

    SUBROUTINE reverse_indices_dlong(array, hist, ri, nbins, a_sz, ri_sz, min_, max_, max_bin, binsz)
       IMPLICIT NONE

       INTEGER*8 :: i, n, ri_sz, a_sz, y, ind, nbins
       INTEGER*8, DIMENSION(a_sz), INTENT(IN) :: array
       !f2py depend(a_sz), array

       INTEGER*4, DIMENSION(nbins) :: hist
       !f2py depend(nbins), hist

       INTEGER*4, DIMENSION(ri_sz), INTENT(INOUT) :: ri
       !f2py depend(ri_sz), ri

       INTEGER*8 :: min_, max_
       REAL*8 :: binsz, max_bin
       INTEGER :: tf

       ri(2) = nbins
       hist(1) = 0

       !print*, 'compute ivec'
       do n = 2, nbins
          ri(n+1) = ri(n) + hist(n)
       enddo

       hist = 0

       !print*, 'compute ovec'
       do i = 1, a_sz
          tf = (array(i) .lt. max_bin) .and. (array(i) .ge. min_) .and. (array(i) .le. max_)
          y = tf * tf
          ind = 1 + ((floor((array(i) - min_) / binsz) + 1) * y)
          hist(ind) = hist(ind) + y
          ri(ri(ind) + hist(ind) + 1) = i - 1
          ri(1) = 1
          hist(1) = 0
          ri(2) = nbins
       enddo

    END SUBROUTINE reverse_indices_dlong

    SUBROUTINE reverse_indices_float(array, hist, ri, nbins, a_sz, ri_sz, min_, max_, max_bin, binsz)
       IMPLICIT NONE

       INTEGER*8 :: i, n, ri_sz, a_sz, y, ind, nbins
       REAL*4, DIMENSION(a_sz), INTENT(IN) :: array
       !f2py depend(a_sz), array

       INTEGER*4, DIMENSION(nbins) :: hist
       !f2py depend(nbins), hist

       INTEGER*4, DIMENSION(ri_sz), INTENT(INOUT) :: ri
       !f2py depend(ri_sz), ri

       REAL*4 :: min_, max_
       REAL*8 :: binsz, max_bin
       INTEGER :: tf

       ri(2) = nbins
       hist(1) = 0

       !print*, 'compute ivec'
       do n = 2, nbins
          ri(n+1) = ri(n) + hist(n)
       enddo

       hist = 0

       !print*, 'compute ovec'
       do i = 1, a_sz
          tf = (array(i) .lt. max_bin) .and. (array(i) .ge. min_) .and. (array(i) .le. max_)
          y = tf * tf
          ind = 1 + ((floor((array(i) - min_) / binsz) + 1) * y)
          hist(ind) = hist(ind) + y
          ri(ri(ind) + hist(ind) + 1) = i - 1
          ri(1) = 1
          hist(1) = 0
          ri(2) = nbins
       enddo

    END SUBROUTINE reverse_indices_float

    SUBROUTINE reverse_indices_dfloat(array, hist, ri, nbins, a_sz, ri_sz, min_, max_, max_bin, binsz)
       IMPLICIT NONE

       INTEGER*8 :: i, n, ri_sz, a_sz, y, ind, nbins
       REAL*8, DIMENSION(a_sz), INTENT(IN) :: array
       !f2py depend(a_sz), array

       INTEGER*4, DIMENSION(nbins) :: hist
       !f2py depend(nbins), hist

       INTEGER*4, DIMENSION(ri_sz), INTENT(INOUT) :: ri
       !f2py depend(ri_sz), ri

       REAL*8 :: min_, max_
       REAL*8 :: binsz, max_bin
       INTEGER :: tf

       ri(2) = nbins
       hist(1) = 0

       !print*, 'compute ivec'
       do n = 2, nbins
          ri(n+1) = ri(n) + hist(n)
       enddo

       hist = 0

       !print*, 'compute ovec'
       do i = 1, a_sz
          tf = (array(i) .lt. max_bin) .and. (array(i) .ge. min_) .and. (array(i) .le. max_)
          y = tf * tf
          ind = 1 + ((floor((array(i) - min_) / binsz) + 1) * y)
          hist(ind) = hist(ind) + y
          ri(ri(ind) + hist(ind) + 1) = i - 1
          ri(1) = 1
          hist(1) = 0
          ri(2) = nbins
       enddo

    END SUBROUTINE reverse_indices_dfloat
END MODULE idl_histogram

