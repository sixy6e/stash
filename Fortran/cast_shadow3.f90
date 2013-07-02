subroutine cast_shadow(DEM, sub_col, sub_row, &
        mask, dy, dx, zenith, k_max, az_case, d0, &
        pi, zmax, l_xoff, l_yoff, cosphc, sinphc)

     implicit none


     integer, intent(in) :: sub_col, sub_row
     integer, dimension(:,:), intent(in) :: DEM, k_max, az_case
     integer*1, dimension(:,:), intent(inout) :: mask
     real, dimension(:,:), intent(in) :: dy, dx, zenith
     !!real, dimension(rows, cols), intent(in) :: lat
     !!real, dimension(rows, cols), intent(in) :: lon
     real, dimension(:,:), intent(in) :: d0, cosphc, sinphc
     !!integer, intent(in) :: cols, rows, sub_col, sub_row
     integer, intent(in) :: l_xoff, l_yoff, zmax
     double precision, intent(in) :: pi

    integer, parameter :: k_setting=1500
    integer :: i, j, k, ipos, jpos, ii, jj, rows, cols
    real :: t, tt, test, htol, yd, xd, zpos
    real :: m_inc(k_setting), n_inc(k_setting), h_offset(k_setting)

    htol = 1.0
    rows = size(DEM, 1)
    cols = size(DEM, 2)

    print *, "The code appears to have passed the arguments"
    print *, "pi: ", pi
    print *, "dem(100,100): ", dem(100,100)
    print *, "cols, rows, sub_col, sub_row", cols, rows, sub_col, sub_row
    print *, "sub_col, sub_row", sub_col, sub_row
    print *, "mask(100,100): ", mask(100,100)
    print *, "dx(100,100): ", dx(100,100)
    print *, "dy(100,100): ", dy(100,100)
    print *, "zenith(100,100): ", zenith(100,100)
    print *, "dx(100,100)*2: ", dx(100,100) * 2
    print *, "dx(100,100)/2: ", dx(100,100) / 2
    print *, "dx(100,100) .gt. 2: ", dx(100,100) .gt. 2
    print *, "dx(100,100) .lt. 2: ", dx(100,100) .lt. 2
    print *, "dx(10+l_yoff,10+l_xoff): ", dx(10+l_yoff,10+l_xoff)

    do i = 1, sub_row
        do j = 1, sub_col
            ii = i + l_yoff
            jj = j + l_xoff
            do k = 1, k_max(ii,jj)
                h_offset(k) = float(k) * d0(ii,jj)
                if (mask(ii,jj) .eq. 1) then
                    if (((i .eq. 1008) .or. (i .eq. 1009)) & 
                        .and. (j .eq. 2857)) then
                        print *, "h_offset(k): ", h_offset(k)
                        print *, "d0(ii,jj): ", d0(ii,jj)
                        print *, "cosphc(ii,jj): ", cosphc(ii,jj)
                        print *, "sinphc(ii,jj): ", sinphc(ii,jj)
                        print *, "dx(ii,jj): ", dx(ii,jj)
                        print *, "dy(ii,jj): ", dy(ii,jj)
                        print *, "k_max(ii,jj): ", k_max(ii,jj)
                        print *, "DEM(ii,jj): ", DEM(ii,jj)
                        print *, "zenith(ii,jj): ", zenith(ii,jj)
                    endif
                    if ((az_case(ii,jj) .eq. 1) .or. &
                        (az_case(ii,jj) .eq. 4)) then
                        n_inc(k) = h_offset(k)*cosphc(ii,jj)/dx(ii,jj)
                        m_inc(k) = -h_offset(k)*sinphc(ii,jj)/dy(ii,jj)
                    else
                        n_inc(k) = -h_offset(k)*cosphc(ii,jj)/dx(ii,jj)
                        m_inc(k) = h_offset(k)*sinphc(ii,jj)/dy(ii,jj)
                    endif
                    !h_offset2(k) = h_offset(k) * tan(pi/2.0 - &
                                   !zenith(ii,jj))
                    h_offset(k) = h_offset(k) * tan(pi/2.0 - &
                                   zenith(ii,jj))
                    t = DEM(ii,jj)
                    tt = t + h_offset(k)
                    if (((i .eq. 1008) .or. (i .eq. 1009)) &
                        .and. (j .eq. 2857)) then
                        print *, "n_inc(k): ", n_inc(k)
                        print *, "m_inc(k): ", m_inc(k)
                        print *, "h_offset(k): ", h_offset(k)
                        print *, "tt: ", tt
                    endif
                    if (tt .le. zmax + htol) then
                        ipos = ifix(float(ii) + m_inc(k))
                        jpos = ifix(float(jj) + n_inc(k))
                        yd = float(ii) + m_inc(k) - float(ipos)
                        xd = float(jj) + n_inc(k) - float(jpos)
                        zpos = DEM(ipos,jpos) * (1.0-yd) * (1.0-xd) + &
                             DEM(ipos,jpos+1) * xd * (1.0-yd) + &
                             DEM(ipos+1,jpos+1) * xd * yd + &
                             DEM(ipos+1,jpos) * (1.0-xd) * yd
                        test = tt - zpos
                    if (((i .eq. 1008) .or. (i .eq. 1009)) &
                        .and. (j .eq. 2857)) then
                        print *, "ipos: ", ipos
                        print *, "jpos: ", jpos
                        print *, "yd: ", yd
                        print *, "xd: ", xd
                        print *, "zpos: ", zpos
                        print *, "tt: ", tt
                    endif
                        if (test .le. htol) then
                            mask(ii,jj) = 0
                        endif
                    endif
                endif
            enddo
        enddo
    enddo
end subroutine cast_shadow

