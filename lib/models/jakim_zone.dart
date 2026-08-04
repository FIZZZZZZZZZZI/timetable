/// A JAKIM e-Solat zone: the unit prayer times are published per, covering
/// one or more districts within a state.
///
/// [kJakimZones] below is a hardcoded snapshot used only as an offline
/// fallback when `PrayerService` can't fetch the live list from
/// solat.my's `/api/locations`; the app otherwise uses whatever that
/// endpoint returns.
class JakimZone {
  final String code;
  final String state;
  final String area;

  const JakimZone({required this.code, required this.state, required this.area});
}

const String kDefaultJakimZone = 'SGR01';

const List<JakimZone> kJakimZones = [
  JakimZone(code: 'JHR01', state: 'Johor', area: 'Pulau Aur dan Pulau Pemanggil'),
  JakimZone(code: 'JHR02', state: 'Johor', area: 'Johor Bahru, Kota Tinggi, Mersing, Kulai'),
  JakimZone(code: 'JHR03', state: 'Johor', area: 'Kluang, Pontian'),
  JakimZone(code: 'JHR04', state: 'Johor', area: 'Batu Pahat, Muar, Segamat, Gemas Johor, Tangkak'),
  JakimZone(code: 'KDH01', state: 'Kedah', area: 'Kota Setar, Kubang Pasu, Pokok Sena (Daerah Kecil)'),
  JakimZone(code: 'KDH02', state: 'Kedah', area: 'Kuala Muda, Yan, Pendang'),
  JakimZone(code: 'KDH03', state: 'Kedah', area: 'Padang Terap, Sik'),
  JakimZone(code: 'KDH04', state: 'Kedah', area: 'Baling'),
  JakimZone(code: 'KDH05', state: 'Kedah', area: 'Bandar Baharu, Kulim'),
  JakimZone(code: 'KDH06', state: 'Kedah', area: 'Langkawi'),
  JakimZone(code: 'KDH07', state: 'Kedah', area: 'Puncak Gunung Jerai'),
  JakimZone(
    code: 'KTN01',
    state: 'Kelantan',
    area: 'Bachok, Kota Bharu, Machang, Pasir Mas, Pasir Puteh, Tanah Merah, Tumpat, Kuala Krai, Mukim Chiku',
  ),
  JakimZone(
    code: 'KTN02',
    state: 'Kelantan',
    area: 'Gua Musang (Daerah Galas Dan Bertam), Jeli, Jajahan Kecil Lojing',
  ),
  JakimZone(code: 'MLK01', state: 'Melaka', area: 'Seluruh Negeri Melaka'),
  JakimZone(code: 'NGS01', state: 'Negeri Sembilan', area: 'Tampin, Jempol'),
  JakimZone(code: 'NGS02', state: 'Negeri Sembilan', area: 'Jelebu, Kuala Pilah, Rembau'),
  JakimZone(code: 'NGS03', state: 'Negeri Sembilan', area: 'Port Dickson, Seremban'),
  JakimZone(code: 'PHG01', state: 'Pahang', area: 'Pulau Tioman'),
  JakimZone(code: 'PHG02', state: 'Pahang', area: 'Kuantan, Pekan, Muadzam Shah'),
  JakimZone(code: 'PHG03', state: 'Pahang', area: 'Jerantut, Temerloh, Maran, Bera, Chenor, Jengka'),
  JakimZone(code: 'PHG04', state: 'Pahang', area: 'Bentong, Lipis, Raub'),
  JakimZone(code: 'PHG05', state: 'Pahang', area: 'Genting Sempah, Janda Baik, Bukit Tinggi'),
  JakimZone(code: 'PHG06', state: 'Pahang', area: 'Cameron Highlands, Genting Higlands, Bukit Fraser'),
  JakimZone(
    code: 'PHG07',
    state: 'Pahang',
    area: 'Zon Khas Daerah Rompin, (Mukim Rompin, Mukim Endau, Mukim Pontian)',
  ),
  JakimZone(code: 'PRK01', state: 'Perak', area: 'Tapah, Slim River, Tanjung Malim'),
  JakimZone(code: 'PRK02', state: 'Perak', area: 'Kuala Kangsar, Sg. Siput, Ipoh, Batu Gajah, Kampar'),
  JakimZone(code: 'PRK03', state: 'Perak', area: 'Lenggong, Pengkalan Hulu, Grik'),
  JakimZone(code: 'PRK04', state: 'Perak', area: 'Temengor, Belum'),
  JakimZone(
    code: 'PRK05',
    state: 'Perak',
    area: 'Kg Gajah, Teluk Intan, Bagan Datuk, Seri Iskandar, Beruas, Parit, Lumut, Sitiawan, Pulau Pangkor',
  ),
  JakimZone(code: 'PRK06', state: 'Perak', area: 'Selama, Taiping, Bagan Serai, Parit Buntar'),
  JakimZone(code: 'PRK07', state: 'Perak', area: 'Bukit Larut'),
  JakimZone(code: 'PLS01', state: 'Perlis', area: 'Seluruh Negeri Perlis'),
  JakimZone(code: 'PNG01', state: 'Pulau Pinang', area: 'Seluruh Negeri Pulau Pinang'),
  JakimZone(
    code: 'SBH01',
    state: 'Sabah',
    area: 'Bahagian Sandakan (Timur), Bukit Garam, Semawang, Temanggong, Tambisan, Bandar Sandakan, Sukau',
  ),
  JakimZone(code: 'SBH02', state: 'Sabah', area: 'Beluran, Telupid, Pinangah, Terusan, Kuamut, Bahagian Sandakan (Barat)'),
  JakimZone(
    code: 'SBH03',
    state: 'Sabah',
    area: 'Lahad Datu, Silabukan, Kunak, Sahabat, Semporna, Tungku, Bahagian Tawau (Timur)',
  ),
  JakimZone(code: 'SBH04', state: 'Sabah', area: 'Bandar Tawau, Balong, Merotai, Kalabakan, Bahagian Tawau (Barat)'),
  JakimZone(code: 'SBH05', state: 'Sabah', area: 'Kudat, Kota Marudu, Pitas, Pulau Banggi, Bahagian Kudat'),
  JakimZone(code: 'SBH06', state: 'Sabah', area: 'Gunung Kinabalu'),
  JakimZone(
    code: 'SBH07',
    state: 'Sabah',
    area: 'Kota Kinabalu, Ranau, Kota Belud, Tuaran, Penampang, Papar, Putatan, Bahagian Pantai Barat',
  ),
  JakimZone(code: 'SBH08', state: 'Sabah', area: 'Pensiangan, Keningau, Tambunan, Nabawan, Bahagian Pendalaman (Atas)'),
  JakimZone(
    code: 'SBH09',
    state: 'Sabah',
    area: 'Beaufort, Kuala Penyu, Sipitang, Tenom, Long Pasia, Membakut, Weston, Bahagian Pendalaman (Bawah)',
  ),
  JakimZone(code: 'SWK01', state: 'Sarawak', area: 'Limbang, Lawas, Sundar, Trusan'),
  JakimZone(code: 'SWK02', state: 'Sarawak', area: 'Miri, Niah, Bekenu, Sibuti, Marudi'),
  JakimZone(code: 'SWK03', state: 'Sarawak', area: 'Pandan, Belaga, Suai, Tatau, Sebauh, Bintulu'),
  JakimZone(code: 'SWK04', state: 'Sarawak', area: 'Sibu, Mukah, Dalat, Song, Igan, Oya, Balingian, Kanowit, Kapit'),
  JakimZone(code: 'SWK05', state: 'Sarawak', area: 'Sarikei, Matu, Julau, Rajang, Daro, Bintangor, Belawai'),
  JakimZone(
    code: 'SWK06',
    state: 'Sarawak',
    area: 'Lubok Antu, Sri Aman, Roban, Debak, Kabong, Lingga, Engkelili, Betong, Spaoh, Pusa, Saratok',
  ),
  JakimZone(code: 'SWK07', state: 'Sarawak', area: 'Serian, Simunjan, Samarahan, Sebuyau, Meludam'),
  JakimZone(code: 'SWK08', state: 'Sarawak', area: 'Kuching, Bau, Lundu, Sematan'),
  JakimZone(code: 'SWK09', state: 'Sarawak', area: 'Zon Khas (Kampung Patarikan)'),
  JakimZone(code: 'SGR01', state: 'Selangor', area: 'Gombak, Petaling, Sepang, Hulu Langat, Hulu Selangor, Shah Alam'),
  JakimZone(code: 'SGR02', state: 'Selangor', area: 'Kuala Selangor, Sabak Bernam'),
  JakimZone(code: 'SGR03', state: 'Selangor', area: 'Klang, Kuala Langat'),
  JakimZone(code: 'TRG01', state: 'Terengganu', area: 'Kuala Terengganu, Marang, Kuala Nerus'),
  JakimZone(code: 'TRG02', state: 'Terengganu', area: 'Besut, Setiu'),
  JakimZone(code: 'TRG03', state: 'Terengganu', area: 'Hulu Terengganu'),
  JakimZone(code: 'TRG04', state: 'Terengganu', area: 'Dungun, Kemaman'),
  JakimZone(code: 'WLY01', state: 'Wilayah Persekutuan', area: 'Kuala Lumpur, Putrajaya'),
  JakimZone(code: 'WLY02', state: 'Wilayah Persekutuan', area: 'Labuan'),
];

/// [kJakimZones] grouped by state, in state-name order, for a grouped
/// dropdown/list UI.
Map<String, List<JakimZone>> get jakimZonesByState {
  final map = <String, List<JakimZone>>{};
  for (final zone in kJakimZones) {
    map.putIfAbsent(zone.state, () => []).add(zone);
  }
  return map;
}
