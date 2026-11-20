// Sinh dữ liệu mẫu: chép nguyên khối mô phỏng (LCG hạt giống cố định) từ dashboard_tinhhinh_trienkhai_v03.html
var SEED = 20261117;
function rnd(){ SEED = (SEED * 1664525 + 1013904223) % 4294967296; return SEED / 4294967296; }
function ri(a,b){ return a + Math.floor(rnd() * (b - a + 1)); }

var NOW = new Date(2026,10,27,17,0,0);          // 27/11/2026 17:00
var DONVI = [
 ['VPTU','Văn phòng Thành ủy','co_quan_tp'],
 ['VPMTTQ','VP Ủy ban MTTQ Thành phố','co_quan_tp'],
 ['VPDBQH','VP Đoàn ĐBQH và HĐND TP','co_quan_tp'],
 ['VPUBND','Văn phòng UBND Thành phố','co_quan_tp'],
 ['SKHCN','Sở Khoa học và Công nghệ','co_quan_tp'],
 ['STC','Sở Tài chính','co_quan_tp'],
 ['TTPVHCC','TT Phục vụ hành chính công','co_quan_tp'],
 ['P_HOANKIEM','Phường Hoàn Kiếm','phuong'],
 ['P_CUANAM','Phường Cửa Nam','phuong'],
 ['P_HONGHA','Phường Hồng Hà','phuong'],
 ['P_HAIBATRUNG','Phường Hai Bà Trưng','phuong'],
 ['P_BACHMAI','Phường Bạch Mai','phuong'],
 ['P_KIMLIEN','Phường Kim Liên','phuong'],
 ['P_DONGDA','Phường Đống Đa','phuong'],
 ['P_OCHODUA','Phường Ô Chợ Dừa','phuong'],
 ['P_VINHTUY','Phường Vĩnh Tuy','phuong'],
 ['P_BADINH','Phường Ba Đình','phuong']
].map(function(u,i){ return {ma:u[0], ten:u[1], khoi:u[2], tt:i+1}; });

/* Lịch kỳ: kỳ ngày T2..T6 từ 17/11 đến 30/11; kỳ tuần 20/11 và 27/11 */
var KY = [];
(function(){
  var stt = 0;
  for (var d = 17; d <= 30; d++){
    var dt = new Date(2026,10,d);
    var w = dt.getDay();
    if (w === 0 || w === 6) continue;
    stt++;
    KY.push({ma:'NGAY_202611'+(d<10?'0'+d:d), loai:'ngay', nhan:(d<10?'0'+d:d)+'/11',
             ten:'Báo cáo ngày '+d+'/11/2026', han:new Date(2026,10,d,16,0,0), stt:stt, soBieu:1});
  }
  KY.push({ma:'TUAN_47_2026', loai:'tuan', nhan:'Tuần 47', ten:'Báo cáo tuần 47 (14–20/11)',
           han:new Date(2026,10,20,16,0,0), stt:1, soBieu:10});
  KY.push({ma:'TUAN_48_2026', loai:'tuan', nhan:'Tuần 48', ten:'Báo cáo tuần 48 (21–27/11)',
           han:new Date(2026,10,27,16,0,0), stt:2, soBieu:10});
})();

/* Mức độ tuân thủ của từng đơn vị — cố định theo hạt giống */
var PROFILE = {};
DONVI.forEach(function(u){
  PROFILE[u.ma] = { pDung: 0.46 + rnd() * 0.46, pMuon: 0.08 + rnd() * 0.16 };
});

function addMin(d,m){ return new Date(d.getTime() + m*60000); }
function fmtDT(d){
  if(!d) return '—';
  var p = function(n){ return n<10 ? '0'+n : ''+n; };
  return p(d.getDate())+'/'+p(d.getMonth()+1)+' '+p(d.getHours())+':'+p(d.getMinutes());
}

var FACT = [];
DONVI.forEach(function(u){
  var pf = PROFILE[u.ma];
  KY.forEach(function(k){
    var denHan = NOW > k.han;
    var r = rnd(), phatHanh = null, nhapDau = null, guiDuyet = null, traLai = 0;
    if (!denHan){
      // kỳ chưa đến hạn: phần lớn chưa xong, một số ít nộp sớm.
      // Mốc thời gian phải nằm trước thời điểm chụp số liệu, không được rơi vào tương lai.
      if (r < 0.18) phatHanh = addMin(NOW, -ri(30, 1500));
      else if (r < 0.45) guiDuyet = addMin(NOW, -ri(30, 2000));
    } else if (r < pf.pDung){
      phatHanh = new Date(k.han.getFullYear(), k.han.getMonth(), k.han.getDate(), ri(8,15), ri(0,59));
    } else if (r < pf.pDung + pf.pMuon && (NOW - k.han) / 60000 > 20){
      // nộp muộn: trong khoảng từ sau hạn đến trước thời điểm chụp số liệu
      phatHanh = addMin(k.han, ri(8, Math.min(1200, Math.floor((NOW - k.han) / 60000) - 5)));
    } else {
      var s = rnd();
      if (s < 0.34) guiDuyet = addMin(k.han, -ri(10, 480));                       // chờ duyệt
      else if (s < 0.50){ guiDuyet = addMin(k.han, -ri(60, 900)); traLai = ri(1,2); } // bị trả lại
      else if (s < 0.74) nhapDau = addMin(k.han, -ri(30, 720));                   // nhập dở, chưa gửi duyệt
    }
    if (phatHanh){
      guiDuyet = addMin(phatHanh, -ri(10, 180));
      if (rnd() < 0.18) traLai = 1;
    }
    if (guiDuyet) nhapDau = addMin(guiDuyet, -ri(15, 300));

    var trangThai = phatHanh ? 'da_phat_hanh' : (traLai > 0 ? 'bi_tra_lai' : (guiDuyet ? 'cho_duyet' : 'chua_nhap'));
    var o = phatHanh ? (phatHanh <= k.han ? 'nop_dung_han' : 'nop_qua_han')
                     : (denHan ? 'chua_nop_qua_han' : 'chua_nop_con_han');

    var hoanTat;
    if (phatHanh)              hoanTat = (rnd() < 0.09) ? k.soBieu - (k.soBieu > 1 ? ri(1,3) : 0) : k.soBieu;
    else if (guiDuyet)         hoanTat = (rnd() < 0.2) ? Math.max(0, k.soBieu - ri(1,2)) : k.soBieu;
    else                       hoanTat = (k.soBieu > 1) ? ri(0, k.soBieu - 1) : 0;
    if (hoanTat > k.soBieu) hoanTat = k.soBieu;
    if (hoanTat < 0) hoanTat = 0;

    FACT.push({
      ma_don_vi:u.ma, ten:u.ten, khoi:u.khoi, ma_ky:k.ma, loai_ky:k.loai, nhan:k.nhan,
      han:k.han, stt_ky:k.stt, den_han:denHan,
      ts_nhap_dau:nhapDau, ts_gui_duyet:guiDuyet, ts_phat_hanh:phatHanh,
      trang_thai:trangThai, o_kiem_dem:o, so_bieu:k.soBieu, so_bieu_hoan_tat:hoanTat,
      so_lan_tra_lai:traLai,
      lech_han_phut: phatHanh ? Math.round((phatHanh - k.han)/60000) : null
    });
  });
});
function s(d){ if(!d) return null; var p=function(n){return n<10?'0'+n:''+n;};
  return d.getFullYear()+'-'+p(d.getMonth()+1)+'-'+p(d.getDate())+' '+p(d.getHours())+':'+p(d.getMinutes())+':00'; }
var KYMAP={}; KY.forEach(function(k){KYMAP[k.ma]=k;});
var out = FACT.map(function(f){
  var u = DONVI.filter(function(x){return x.ma===f.ma_don_vi;})[0];
  return {ma_don_vi:f.ma_don_vi, ten_don_vi:f.ten, tt_don_vi:u.tt,
    khoi:f.khoi==='co_quan_tp'?'Cơ quan Thành phố':'Phường xã',
    ma_ky:f.ma_ky, loai_ky:f.loai_ky==='ngay'?'Kỳ ngày':'Kỳ tuần', nhan_ky:f.nhan, ten_ky:KYMAP[f.ma_ky].ten,
    stt_ky:f.stt_ky, han_nop:s(f.han), den_han:f.den_han?1:0,
    ts_nhap_dau:s(f.ts_nhap_dau), ts_gui_duyet:s(f.ts_gui_duyet), ts_phat_hanh:s(f.ts_phat_hanh),
    trang_thai:f.trang_thai, o_kiem_dem:f.o_kiem_dem, so_bieu:f.so_bieu, so_bieu_hoan_tat:f.so_bieu_hoan_tat,
    so_lan_tra_lai:f.so_lan_tra_lai, lech_han_phut:f.lech_han_phut, moc_chup:s(NOW)};
});
require('fs').writeFileSync(__dirname+'/du_lieu_mau.json', JSON.stringify(out,null,0));
console.log(out.length+' dòng', JSON.stringify(out[0]));
