program prepbufr_decode_csv
!
! read all observations out from prepbufr. 
! read bufr table from prepbufr file
! write all obs to a CSV that can be easily read by Python
!
! shawn.s.murdzek@noaa.gov
! Date Created: 14 October 2022
!
 implicit none

 integer, parameter :: mxmn=65, mxlv=250
 integer, parameter :: nhd=8, nob=13, nqc=8, noe=7, ndrift=3, nsst=5, nfc=3, ncld=3, &
                       ngoescld=4, nmaxmin=2, naircft=2, nprwe=1, nprv=1,nsprv=1,    &
                       nhowv=1, nceil=1, nqifn=1, nhblcs=1, ntsb=1, nacid=1, nrsrd=1

! Define fields to be read from prepbufr file
! Some combinations of fields result in the following error. If that is the
! case, try rearranging how the fields are distributed among the arrays.
! Error: INPUT STRING STORE NODES (MNEMONICS) THAT ARE IN MORE THAN ONE REPLICATION GROUP
 character(4), dimension(nhd)      :: hda=(/ 'SID','XOB','YOB','DHR','TYP','ELV','SAID','T29' /)
 character(4), dimension(nob)      :: oba=(/ 'POB','QOB','TOB','ZOB','UOB','VOB','PWO','MXGS','HOVI','CAT','PRSS','TDO','PMO' /)
 character(4), dimension(nqc)      :: qca=(/ 'PQM','QQM','TQM','ZQM','WQM','NUL','PWQ','PMQ' /)
 character(4), dimension(noe)      :: oea=(/ 'POE','QOE','TOE','NUL','WOE','NUL','PWE' /)
 character(4), dimension(ndrift)   :: drifta=(/ 'XDR','YDR','HRDR' /)
 character(5), dimension(nsst)     :: ssta=(/ 'MSST','DBSS','SST1','SSTQM','SSTOE' /)
 character(3), dimension(nfc)      :: fca=(/ 'TFC','UFC','VFC' /)
 character(4), dimension(ncld)     :: clda=(/ 'VSSO','CLAM','HOCB' /)
 character(7), dimension(ngoescld) :: goesclda=(/ 'CDTP','TOCC','GCDTT','CDTP_QM' /)
 character(4), dimension(nmaxmin)  :: maxmina=(/ 'MXTM','MITM' /)
 character(4), dimension(naircft)  :: aircfta=(/ 'POAF','IALR' /)
 character(8), dimension(nprwe)    :: prwea=(/ 'PRWE' /)
 character(8), dimension(nprv)     :: prva=(/ 'PRVSTG' /)
 character(8), dimension(nsprv)    :: sprva=(/ 'SPRVSTG' /)
 character(8), dimension(nhowv)    :: howva=(/ 'HOWV' /)
 character(8), dimension(nceil)    :: ceila=(/ 'CEILING' /)
 character(8), dimension(nqifn)    :: qifna=(/ 'QIFN' /)
 character(8), dimension(nhblcs)   :: hblcsa=(/ 'HBLCS' /)
 character(8), dimension(ntsb)     :: tsba=(/ 'TSB' /)
 character(8), dimension(nacid)    :: acida=(/ 'ACID' /)
 character(8), dimension(nrsrd)    :: rsrda=(/ 'RSRD' /)

 character(80) :: hdstr,obstr,qcstr,oestr,driftstr,sststr,fcstr,cldstr,goescldstr,maxminstr,       &
                  aircftstr,prwestr,prvstr,sprvstr,howvstr,ceilstr,qifnstr,hblcsstr,tsbstr,acidstr,&
                  rsrdstr

 real(8) :: hdr(mxmn),obs(mxmn,mxlv),qcf(mxmn,mxlv),oer(mxmn,mxlv),drift(mxmn,mxlv),sst(mxmn,mxlv), &
            fc(mxmn,mxlv),cld(mxmn,mxlv),goescld(mxmn,mxlv),maxmin(mxmn,mxlv),aircft(mxmn,mxlv),    &
            prwe(mxmn,mxlv),prv(mxmn,mxlv),sprv(mxmn,mxlv),howv(mxmn,mxlv),ceil(mxmn,mxlv),         &
            qifn(mxmn,mxlv),hblcs(mxmn,mxlv),tsb(mxmn,mxlv),acid(mxmn,mxlv),rsrd(mxmn,mxlv) 

 real :: bmiss=1.0e9
 real(8) :: tpc(mxlv,100)
 integer :: tvflg(mxlv)

 INTEGER        :: ireadmg,ireadsb

 character(8)   :: subset
 integer        :: unit_in=10,idate,nmsg,ntb,nobs

 character(8)   :: c_sid,c_prvstg,c_sprvstg
 real(8)        :: rstation_id,r_prvstg,r_sprvstg
 equivalence(rstation_id,c_sid)
 equivalence(r_prvstg,c_prvstg)
 equivalence(r_sprvstg,c_sprvstg)

 integer        :: i,j,k,iret_max,levs
 integer, dimension(20) :: iret
 real           :: vtcd

 print*, 'starting prepbufr_decode_csv program'

! Create strings to read prepbufr fields
 write(hdstr,'(*(a," "))') hda
 write(obstr,'(*(a," "))') oba
 write(qcstr,'(*(a," "))') qca
 write(oestr,'(*(a," "))') oea
 write(driftstr,'(*(a," "))') drifta
 write(sststr,'(*(a," "))') ssta
 write(fcstr,'(*(a," "))') fca
 write(cldstr,'(*(a," "))') clda
 write(goescldstr,'(*(a," "))') goesclda
 write(maxminstr,'(*(a," "))') maxmina
 write(aircftstr,'(*(a," "))') aircfta
 write(prwestr,'(*(a," "))') prwea
 write(prvstr,'(*(a," "))') prva
 write(sprvstr,'(*(a," "))') sprva
 write(howvstr,'(*(a," "))') howva
 write(ceilstr,'(*(a," "))') ceila
 write(qifnstr,'(*(a," "))') qifna
 write(hblcsstr,'(*(a," "))') hblcsa
 write(tsbstr,'(*(a," "))') tsba
 write(acidstr,'(*(a," "))') acida
 write(rsrdstr,'(*(a," "))') rsrda

! Open files
 open(24,file='prepbufr.table')
 open(unit_in,file='prepbufr',form='unformatted',status='old')
 open(100,file='prepbufr.csv')

! nmsg = Message number
! ntb = Observation number in this particular message
 write(100,'(1x *(g0,","))') 'nmsg','subset','cycletime','ntb',(trim(hda(i)),i=1,nhd),   &
                             (trim(oba(i)),i=1,nob),(trim(qca(i)),i=1,nqc),              &
                             (trim(oea(i)),i=1,noe),(trim(drifta(i)),i=1,ndrift),        &
                             (trim(ssta(i)),i=1,nsst),(trim(fca(i)),i=1,nfc),            &            
                             (trim(clda(i)),i=1,ncld),(trim(goesclda(i)),i=1,ngoescld),  &
                             (trim(maxmina(i)),i=1,nmaxmin),                             & 
                             (trim(aircfta(i)),i=1,naircft),(trim(prwea(i)),i=1,nprwe),  &
                             (trim(prva(i)),i=1,nprv),(trim(sprva(i)),i=1,nsprv),        &
                             (trim(howva(i)),i=1,nhowv),(trim(ceila(i)),i=1,nceil),      &
                             (trim(qifna(i)),i=1,nqifn),(trim(hblcsa(i)),i=1,nhblcs),    &
                             (trim(tsba(i)),i=1,ntsb),(trim(acida(i)),i=1,nacid),        &
                             (trim(rsrda(i)),i=1,nrsrd),'tvflg','vtcd'

 call openbf(unit_in,'IN',unit_in)
 call dxdump(unit_in,24)
 call datelen(10)

! Determine code associated with virtual temperature (VIRTMP) step
 call ufbqcd(unit_in,'VIRTMP',vtcd)
 print*, 'VIRTMP code =', vtcd

 nmsg=0
 msg_report: do while (ireadmg(unit_in,subset,idate) == 0)
   nmsg=nmsg+1
   ntb = 0
   sb_report: do while (ireadsb(unit_in) == 0)
     ntb = ntb+1
     iret = 0

     ! Determine if temperature is virtual or sensible (code comes from
     ! read_prepbufr.f90 in GSI)
     call ufbevn(unit_in,tpc,1,mxlv,100,levs,'TPC')
     do k=1,levs
       tvflg(k)=1
       do j=1,100
         if (tpc(k,j)==vtcd) tvflg(k)=0
         if (tpc(k,j)>=bmiss) exit
       enddo
     enddo

     call ufbint(unit_in,hdr,mxmn,1   ,iret(1),hdstr)
     call ufbint(unit_in,oer,mxmn,mxlv,iret(2),oestr)
     call ufbint(unit_in,qcf,mxmn,mxlv,iret(3),qcstr)
     call ufbint(unit_in,obs,mxmn,mxlv,iret(4),obstr)
     call ufbint(unit_in,drift,mxmn,mxlv,iret(5),driftstr)
     call ufbint(unit_in,sst,mxmn,mxlv,iret(6),sststr)
     call ufbint(unit_in,fc,mxmn,mxlv,iret(7),fcstr)
     call ufbint(unit_in,cld,mxmn,mxlv,iret(8),cldstr)
     call ufbint(unit_in,goescld,mxmn,mxlv,iret(9),goescldstr)
     call ufbint(unit_in,maxmin,mxmn,mxlv,iret(10),maxminstr)
     call ufbint(unit_in,aircft,mxmn,mxlv,iret(11),aircftstr)
     call ufbint(unit_in,prwe,mxmn,mxlv,iret(12),prwestr)
     call ufbint(unit_in,prv,mxmn,mxlv,iret(13),prvstr)
     call ufbint(unit_in,sprv,mxmn,mxlv,iret(14),sprvstr)
     call ufbint(unit_in,howv,mxmn,mxlv,iret(15),howvstr)
     call ufbint(unit_in,ceil,mxmn,mxlv,iret(16),ceilstr)
     call ufbint(unit_in,qifn,mxmn,mxlv,iret(17),qifnstr)
     call ufbint(unit_in,hblcs,mxmn,mxlv,iret(18),hblcsstr)
     call ufbint(unit_in,tsb,mxmn,mxlv,iret(19),tsbstr)
     call ufbint(unit_in,acid,mxmn,mxlv,iret(20),acidstr)
     call ufbint(unit_in,rsrd,mxmn,mxlv,iret(21),rsrdstr)

     rstation_id=hdr(1)
     iret_max = maxval(iret)
     do k=1,iret_max
       if (trim(subset) == 'MSONET') then
         r_prvstg=prv(1,k)
         r_sprvstg=sprv(1,k)
         write(100, '(1x *(g0,","))') nmsg,trim(subset),idate,ntb,trim(c_sid),(hdr(i),i=2,nhd), &
                                      (obs(i,k),i=1,nob),(qcf(i,k),i=1,nqc),(oer(i,k),i=1,noe), &
                                      (drift(i,k),i=1,ndrift),(sst(i,k),i=1,nsst),              &
                                      (fc(i,k),i=1,nfc),(cld(i,k),i=1,ncld),                    &
                                      (goescld(i,k),i=1,ngoescld),(maxmin(i,k),i=1,nmaxmin),    &
                                      (aircft(i,k),i=1,naircft),(prwe(i,k),i=1,nprwe),          &
                                      trim(c_prvstg),trim(c_sprvstg),                           &
                                      (howv(i,k),i=1,nhowv),(ceil(i,k),i=1,nceil),              &
                                      (qifn(i,k),i=1,nqifn),(hblcs(i,k),i=1,nhblcs),            &
                                      (tsb(i,k),i=1,ntsb),(acid(i,k),i=1,nacid),                &
                                      (rsrd(i,k),i=1,nrsrd),tvflg(k),vtcd
       else
         write(100, '(1x *(g0,","))') nmsg,trim(subset),idate,ntb,trim(c_sid),(hdr(i),i=2,nhd), &
                                      (obs(i,k),i=1,nob),(qcf(i,k),i=1,nqc),(oer(i,k),i=1,noe), &
                                      (drift(i,k),i=1,ndrift),(sst(i,k),i=1,nsst),              &
                                      (fc(i,k),i=1,nfc),(cld(i,k),i=1,ncld),                    &
                                      (goescld(i,k),i=1,ngoescld),(maxmin(i,k),i=1,nmaxmin),    &
                                      (aircft(i,k),i=1,naircft),(prwe(i,k),i=1,nprwe),          &
                                      (prv(i,k),i=1,nprv),(sprv(i,k),i=1,nsprv),                &
                                      (howv(i,k),i=1,nhowv),(ceil(i,k),i=1,nceil),              &
                                      (qifn(i,k),i=1,nqifn),(hblcs(i,k),i=1,nhblcs),            &
                                      (tsb(i,k),i=1,ntsb),(acid(i,k),i=1,nacid),tvflg(k),vtcd
       endif
     enddo
   enddo sb_report
 enddo msg_report
 call closbf(unit_in)

end program
