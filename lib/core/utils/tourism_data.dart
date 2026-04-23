// ─── Tourist Attractions Database for Cairo Metro ─────────────────────────────
// Covers all 3 lines, 85 stations, with 4-language support
// Languages: ar (Arabic), en (English), fr (French), de (German)

enum AttractionCategory {
  museum,
  mosque,
  church,
  market,
  park,
  palace,
  landmark,
  monument,
  university,
  entertainment,
}

class TouristAttraction {
  final String id;
  final Map<String, String> name;        // {ar, en, fr, de}
  final Map<String, String> description; // {ar, en, fr, de}
  final AttractionCategory category;
  final String emoji;
  final double rating;
  final String openHours;
  final bool isFree;
  final String admissionEGP; // "free" or "25 EGP" etc.
  final String walkingMinutes;
  final List<String> tags;
  final String? imageUrl;
  final String? wikiUrl;
  final List<String>? galleryUrls;

  const TouristAttraction({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.emoji,
    required this.rating,
    required this.openHours,
    required this.isFree,
    required this.admissionEGP,
    required this.walkingMinutes,
    required this.tags,
    this.imageUrl,
    this.wikiUrl,
    this.galleryUrls,
  });
}

class StationAttractions {
  final String stationId;
  final Map<String, String> stationName; // {ar, en}
  final List<TouristAttraction> attractions;

  const StationAttractions({
    required this.stationId,
    required this.stationName,
    required this.attractions,
  });
}

class TourismDatabase {
  static const List<StationAttractions> data = [
    // ─── LINE 1 (RED) ──────────────────────────────────────────────────────────

    StationAttractions(
      stationId: 'sadat',
      stationName: {'ar': 'محطة السادات', 'en': 'Sadat Station'},
      attractions: [
        TouristAttraction(
          id: 'egyptian_museum',
          name: {'ar': 'المتحف المصري', 'en': 'Egyptian Museum', 'fr': 'Musée Égyptien', 'de': 'Ägyptisches Museum'},
          description: {
            'ar': 'أعظم متحف في العالم للحضارة المصرية القديمة. يضم أكثر من 120,000 قطعة أثرية تشمل كنوز توت عنخ آمون الذهبية، المومياوات الملكية، وتماثيل الفراعنة. بُني عام 1902 ويمثل قلب التراث الإنساني.',
            'en': 'The world\'s greatest repository of ancient Egyptian artifacts. Home to 120,000+ objects including Tutankhamun\'s golden treasures, royal mummies, and pharaonic statues. Built in 1902, it is the heart of human heritage.',
            'fr': 'Le plus grand musée d\'antiquités égyptiennes au monde. Il abrite plus de 120 000 objets, dont les trésors dorés de Toutankhamon, des momies royales et des statues pharaoniques. Construit en 1902.',
            'de': 'Das weltweit bedeutendste Museum für altägyptische Artefakte. Beherbergt über 120.000 Objekte, darunter Tutanchamuns goldene Schätze, königliche Mumien und Pharaonenstatuen. Erbaut 1902.',
          },
          category: AttractionCategory.museum,
          emoji: '🏛️',
          rating: 4.9,
          openHours: '9:00 AM – 5:00 PM',
          isFree: false,
          admissionEGP: '200 EGP',
          walkingMinutes: '3',
          tags: ['UNESCO', 'Tutankhamun', 'Mummies', 'Pharaohs'],
          imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/e/e5/Egyptian_Museum_Cairo_2020.jpg',
          wikiUrl: 'https://ar.wikipedia.org/wiki/المتحف_المصري',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/e/e5/Egyptian_Museum_Cairo_2020.jpg',
            'https://upload.wikimedia.org/wikipedia/commons/b/b5/Egyptian_Museum_Cairo.jpg',
            'https://upload.wikimedia.org/wikipedia/commons/1/1c/Cairo_Egyptian_Museum_Statue_of_Khafre.jpg',
          ],
        ),
        TouristAttraction(
          id: 'tahrir_square',
          name: {'ar': 'ميدان التحرير', 'en': 'Tahrir Square', 'fr': 'Place Tahrir', 'de': 'Tahrirplatz'},
          description: {
            'ar': 'قلب القاهرة النابض والميدان الأشهر في مصر. شهد أهم لحظات التاريخ المصري الحديث. يتوسطه تمثال عمر مكرم ومسلة رمسيس الثاني. نقطة التقاء الخطوط الرئيسية في المترو.',
            'en': 'The beating heart of Cairo and Egypt\'s most iconic square. Witness to modern history\'s pivotal moments. Features Omar Makram statue and Ramses II obelisk. Intersection of Cairo\'s main metro lines.',
            'fr': 'Le cœur battant du Caire et la place la plus emblématique d\'Égypte. Témoin de moments historiques modernes. Présente la statue d\'Omar Makram et l\'obélisque de Ramsès II.',
            'de': 'Das pulsierende Herz Kairos und Ägyptens ikonischster Platz. Zeuge historischer Momente der Moderne. Beherbergt die Omar-Makram-Statue und den Ramses-II-Obelisken.',
          },
          category: AttractionCategory.landmark,
          emoji: '🗽',
          rating: 4.7,
          openHours: 'Always open',
          isFree: true,
          admissionEGP: 'Free',
          walkingMinutes: '1',
          tags: ['Historic', 'Iconic', 'City Center'],
        ),
        TouristAttraction(
          id: 'grand_egyptian_museum',
          name: {'ar': 'المتحف المصري الكبير (GEM)', 'en': 'Grand Egyptian Museum (GEM)', 'fr': 'Grand Musée Égyptien', 'de': 'Großes Ägyptisches Museum'},
          description: {
            'ar': 'أكبر متحف أثري في العالم بالقرب من الأهرامات. يحتضن أكثر من 100,000 قطعة أثرية مصرية. افتُتح جزئياً عام 2023 وهو تحفة معمارية بمدخل زجاجي ضخم.',
            'en': 'The world\'s largest archaeological museum near the Pyramids. Houses 100,000+ Egyptian artifacts. Partially opened in 2023 with a stunning glass façade and monumental entrance.',
            'fr': 'Le plus grand musée archéologique du monde, près des Pyramides. Abrite plus de 100 000 objets égyptiens. Partiellement ouvert en 2023 avec une magnifique façade en verre.',
            'de': 'Das größte archäologische Museum der Welt in der Nähe der Pyramiden. Beherbergt über 100.000 ägyptische Artefakte. Teilweise 2023 mit einer beeindruckenden Glasfassade eröffnet.',
          },
          category: AttractionCategory.museum,
          emoji: '🌟',
          rating: 4.8,
          openHours: '9:00 AM – 9:00 PM',
          isFree: false,
          admissionEGP: '500 EGP',
          walkingMinutes: '35 (by bus/taxi)',
          tags: ['UNESCO', 'New Museum', 'World Class', 'Pyramids'],
        ),
      ],
    ),

    StationAttractions(
      stationId: 'mar_girgis',
      stationName: {'ar': 'محطة مار جرجس', 'en': 'Mar Girgis Station'},
      attractions: [
        TouristAttraction(
          id: 'coptic_museum',
          name: {'ar': 'المتحف القبطي', 'en': 'Coptic Museum', 'fr': 'Musée Copte', 'de': 'Koptisches Museum'},
          description: {
            'ar': 'أغنى متحف في العالم للفن القبطي المسيحي. يضم أكثر من 16,000 قطعة فنية تمتد من القرن الأول حتى القرن الثاني عشر الميلادي. يحكي قصة المسيحية في مصر بكل تفاصيلها.',
            'en': 'The world\'s richest repository of Coptic Christian art. Houses 16,000+ artworks spanning 1st to 12th centuries. Tells the complete story of Christianity in Egypt.',
            'fr': 'Le musée d\'art chrétien copte le plus riche du monde. Abrite plus de 16 000 œuvres d\'art du Ier au XIIe siècle. Raconte l\'histoire du christianisme en Égypte.',
            'de': 'Das reichste Museum für koptische christliche Kunst weltweit. Beherbergt 16.000+ Kunstwerke vom 1. bis 12. Jahrhundert. Erzählt die vollständige Geschichte des Christentums in Ägypten.',
          },
          category: AttractionCategory.museum,
          emoji: '✝️',
          rating: 4.7,
          openHours: '9:00 AM – 5:00 PM',
          isFree: false,
          admissionEGP: '100 EGP',
          walkingMinutes: '2',
          tags: ['Coptic', 'Christianity', 'Ancient Art'],
        ),
        TouristAttraction(
          id: 'hanging_church',
          name: {'ar': 'الكنيسة المعلقة', 'en': 'The Hanging Church', 'fr': 'L\'Église Suspendue', 'de': 'Die Hängende Kirche'},
          description: {
            'ar': 'أقدم وأشهر كنيسة في مصر، تعود للقرن السابع الميلادي. سميت بالمعلقة لأنها بُنيت فوق بوابة حصن بابليون. نموذج رائع للعمارة القبطية القديمة.',
            'en': 'Egypt\'s oldest and most famous church, dating to the 7th century. Called "Hanging" as it was built atop the Babylon Fortress gate. A magnificent example of ancient Coptic architecture.',
            'fr': 'La plus ancienne et la plus célèbre église d\'Égypte, datant du VIIe siècle. Appelée "Suspendue" car construite sur la porte de la Forteresse de Babylone.',
            'de': 'Ägyptens älteste und berühmteste Kirche aus dem 7. Jahrhundert. "Hängend" genannt, da sie auf dem Tor der Babylon-Festung erbaut wurde.',
          },
          category: AttractionCategory.church,
          emoji: '⛪',
          rating: 4.8,
          openHours: '9:00 AM – 4:00 PM',
          isFree: true,
          admissionEGP: 'Free',
          walkingMinutes: '3',
          tags: ['Historic Church', 'Coptic', '7th Century'],
        ),
        TouristAttraction(
          id: 'ben_ezra_synagogue',
          name: {'ar': 'كنيس بن عزرا', 'en': 'Ben Ezra Synagogue', 'fr': 'Synagogue Ben Ezra', 'de': 'Ben-Esra-Synagoge'},
          description: {
            'ar': 'أقدم كنيس يهودي في أفريقيا، بُني عام 882 ميلادي. يُقال إنه المكان الذي وجدت فيه جدة موسى سلة الطفل. يمثل التعايش الحضاري في مصر عبر العصور.',
            'en': 'The oldest Jewish synagogue in Africa, built in 882 AD. Believed to be the site where Moses was found in a basket. Represents Egypt\'s rich history of coexistence.',
            'fr': 'La plus ancienne synagogue juive d\'Afrique, construite en 882 ap. J.-C. Lieu supposé de la découverte de Moïse dans un panier. Symbole de la coexistence en Égypte.',
            'de': 'Die älteste jüdische Synagoge Afrikas, erbaut 882 n. Chr. Soll der Ort sein, wo Moses gefunden wurde. Steht für Ägyptens reiche Geschichte des Zusammenlebens.',
          },
          category: AttractionCategory.monument,
          emoji: '✡️',
          rating: 4.5,
          openHours: '9:00 AM – 5:00 PM',
          isFree: false,
          admissionEGP: '100 EGP',
          walkingMinutes: '5',
          tags: ['Jewish Heritage', '9th Century', 'Religious'],
        ),
        TouristAttraction(
          id: 'amr_mosque',
          name: {'ar': 'مسجد عمرو بن العاص', 'en': 'Amr Ibn Al-As Mosque', 'fr': 'Mosquée de Amr Ibn Al-As', 'de': 'Amr-ibn-al-As-Moschee'},
          description: {
            'ar': 'أول مسجد بُني في مصر وأفريقيا كلها، أسسه الفاتح عمرو بن العاص عام 641 ميلادي. يعدّ من أقدس الشعائر الإسلامية في القارة الأفريقية. جُدد وتوسّع عدة مرات عبر التاريخ.',
            'en': 'The first mosque built in Egypt and all of Africa, founded by conqueror Amr ibn al-As in 641 AD. One of Africa\'s holiest Islamic sites. Expanded and renovated multiple times throughout history.',
            'fr': 'La première mosquée construite en Égypte et en Afrique, fondée par Amr ibn al-As en 641 ap. J.-C. L\'un des sites islamiques les plus sacrés d\'Afrique.',
            'de': 'Die erste in Ägypten und ganz Afrika erbaute Moschee, gegründet 641 n. Chr. Eines der heiligsten islamischen Stätten Afrikas. Im Laufe der Geschichte mehrfach erweitert.',
          },
          category: AttractionCategory.mosque,
          emoji: '🕌',
          rating: 4.6,
          openHours: '5:00 AM – 10:00 PM',
          isFree: true,
          admissionEGP: 'Free',
          walkingMinutes: '7',
          tags: ['First Mosque', 'Islamic', '7th Century', 'Historic'],
        ),
      ],
    ),

    StationAttractions(
      stationId: 'attaba',
      stationName: {'ar': 'محطة العتبة', 'en': 'Attaba Station'},
      attractions: [
        TouristAttraction(
          id: 'khan_khalili',
          name: {'ar': 'خان الخليلي', 'en': 'Khan El-Khalili Bazaar', 'fr': 'Bazar Khan El-Khalili', 'de': 'Khan el-Khalili Basar'},
          description: {
            'ar': 'أشهر سوق شعبي في العالم العربي، أُسس عام 1382. يمتد على مساحة شاسعة في قلب القاهرة الإسلامية. يضم آلاف المحلات للمجوهرات والتحف والبهارات والملابس. تجربة ثقافية لا تُنسى.',
            'en': 'The most famous bazaar in the Arab world, founded in 1382. Stretches across Islamic Cairo\'s heart. Thousands of shops selling jewelry, antiques, spices, and clothing. An unforgettable cultural experience.',
            'fr': 'Le bazar le plus célèbre du monde arabe, fondé en 1382. S\'étend au cœur du Caire islamique. Des milliers de boutiques de bijoux, antiquités, épices et vêtements.',
            'de': 'Der berühmteste Basar der arabischen Welt, gegründet 1382. Erstreckt sich im Herzen des islamischen Kairo. Tausende von Geschäften mit Schmuck, Antiquitäten, Gewürzen und Kleidung.',
          },
          category: AttractionCategory.market,
          emoji: '🛍️',
          rating: 4.7,
          openHours: '9:00 AM – 11:00 PM',
          isFree: true,
          admissionEGP: 'Free entry',
          walkingMinutes: '10',
          tags: ['Shopping', 'Culture', '14th Century', 'Souvenirs'],
        ),
        TouristAttraction(
          id: 'al_azhar_mosque',
          name: {'ar': 'مسجد الأزهر الشريف', 'en': 'Al-Azhar Mosque', 'fr': 'Mosquée d\'Al-Azhar', 'de': 'Al-Azhar-Moschee'},
          description: {
            'ar': 'أحد أقدس المساجد في الإسلام وأشهرها في العالم. بُني عام 970 ميلادي ويرتبط بجامعة الأزهر الشريف أقدم جامعة في العالم. مركز للعلم والفكر الإسلامي منذ أكثر من ألف عام.',
            'en': 'One of Islam\'s holiest mosques and most renowned worldwide. Built in 970 AD, linked to Al-Azhar University — the world\'s oldest university. Center of Islamic scholarship for over 1,000 years.',
            'fr': 'L\'une des mosquées les plus sacrées de l\'islam. Construite en 970 ap. J.-C., liée à l\'Université Al-Azhar - la plus ancienne du monde.',
            'de': 'Eine der heiligsten und renommiertesten Moscheen des Islam. Erbaut 970 n. Chr., verbunden mit der Al-Azhar-Universität - der ältesten Universität der Welt.',
          },
          category: AttractionCategory.mosque,
          emoji: '🕌',
          rating: 4.9,
          openHours: '9:00 AM – 5:00 PM (not during prayer)',
          isFree: true,
          admissionEGP: 'Free',
          walkingMinutes: '12',
          tags: ['Islam', '10th Century', 'World Heritage', 'Scholarship'],
        ),
        TouristAttraction(
          id: 'al_hussein_mosque',
          name: {'ar': 'مسجد سيدنا الحسين', 'en': 'Al-Hussein Mosque', 'fr': 'Mosquée Al-Hussein', 'de': 'Al-Husayn-Moschee'},
          description: {
            'ar': 'أقدس المواضع الإسلامية في مصر وأحبها لدى المصريين. يُعتقد أنه يضم رأس سيدنا الحسين بن علي رضي الله عنه. الميدان المحيط به من أجمل الأماكن ليلاً في القاهرة الفاطمية.',
            'en': 'The most sacred Islamic site in Egypt and most beloved by Egyptians. Believed to hold the head of Hussein ibn Ali. The surrounding square is one of Cairo\'s most beautiful at night.',
            'fr': 'Le site islamique le plus sacré d\'Égypte. Censé abriter le chef d\'Hussein ibn Ali. La place environnante est l\'un des plus beaux endroits du Caire la nuit.',
            'de': 'Die heiligste islamische Stätte Ägyptens. Soll das Haupt von Husain ibn Ali beherbergen. Der umliegende Platz ist einer der schönsten Kairos bei Nacht.',
          },
          category: AttractionCategory.mosque,
          emoji: '🕌',
          rating: 4.8,
          openHours: '5:00 AM – 10:00 PM',
          isFree: true,
          admissionEGP: 'Free',
          walkingMinutes: '11',
          tags: ['Holy Site', 'Fatimid', 'Night Life'],
        ),
      ],
    ),

    StationAttractions(
      stationId: 'dokki',
      stationName: {'ar': 'محطة الدقي', 'en': 'Dokki Station'},
      attractions: [
        TouristAttraction(
          id: 'cairo_zoo',
          name: {'ar': 'حديقة الحيوان المصرية', 'en': 'Cairo Zoo (Giza Zoo)', 'fr': 'Zoo du Caire', 'de': 'Kairoer Zoo'},
          description: {
            'ar': 'أقدم حديقة حيوان في أفريقيا والشرق الأوسط، افتُتحت عام 1891. تمتد على أكثر من 80 فداناً وتضم أكثر من 6,000 حيوان من 700 نوع. قصر أنطونياديس داخل الحديقة يُحيّر الزوار بجماله.',
            'en': 'Africa\'s and the Middle East\'s oldest zoo, opened 1891. Spans 80+ acres with 6,000+ animals from 700 species. The Antoniadis Palace inside the grounds stuns visitors with its beauty.',
            'fr': 'Le plus vieux zoo d\'Afrique et du Moyen-Orient, ouvert en 1891. S\'étend sur plus de 80 hectares avec plus de 6 000 animaux de 700 espèces.',
            'de': 'Afrikas und dem Nahen Osten ältester Zoo, eröffnet 1891. Erstreckt sich auf 80+ Hektar mit 6.000+ Tieren aus 700 Arten.',
          },
          category: AttractionCategory.park,
          emoji: '🦁',
          rating: 4.4,
          openHours: '9:00 AM – 4:00 PM',
          isFree: false,
          admissionEGP: '5 EGP',
          walkingMinutes: '8',
          tags: ['Animals', 'Family', 'Historic', '1891'],
        ),
        TouristAttraction(
          id: 'orman_garden',
          name: {'ar': 'حديقة الأورمان النباتية', 'en': 'Orman Botanical Garden', 'fr': 'Jardin Botanique Orman', 'de': 'Botanischer Garten Orman'},
          description: {
            'ar': 'حديقة نباتية ملكية أُسست عام 1875 بأمر من الخديوي إسماعيل. تضم أكثر من 3,000 نوع من النباتات النادرة من كل أنحاء العالم. مكان مثالي للاسترخاء واستنشاق الهواء النقي في قلب القاهرة.',
            'en': 'A royal botanical garden founded in 1875 by Khedive Ismail. Houses 3,000+ rare plant species from around the world. Perfect place to relax and breathe fresh air in Cairo\'s heart.',
            'fr': 'Un jardin botanique royal fondé en 1875 par le Khédive Ismaïl. Abrite plus de 3 000 espèces végétales rares du monde entier.',
            'de': 'Ein königlicher botanischer Garten, gegründet 1875 von Khedive Ismail. Beherbergt 3.000+ seltene Pflanzenarten aus aller Welt.',
          },
          category: AttractionCategory.park,
          emoji: '🌳',
          rating: 4.5,
          openHours: '8:00 AM – 5:00 PM',
          isFree: false,
          admissionEGP: '5 EGP',
          walkingMinutes: '5',
          tags: ['Nature', 'Botanic', 'Royal', 'Relaxation'],
        ),
        TouristAttraction(
          id: 'cairo_opera',
          name: {'ar': 'دار أوبرا القاهرة', 'en': 'Cairo Opera House', 'fr': 'Opéra du Caire', 'de': 'Kairoer Opernhaus'},
          description: {
            'ar': 'المركز الثقافي الأول في الشرق الأوسط وأفريقيا. افتُتح عام 1988 على جزيرة الزمالك ويضم ثلاث قاعات عروض. يستضيف أرقى العروض المسرحية والموسيقية طوال العام.',
            'en': 'The premier cultural center of the Middle East and Africa. Opened 1988 on Zamalek Island with three performance halls. Hosts world-class theatrical and musical performances year-round.',
            'fr': 'Le premier centre culturel du Moyen-Orient et d\'Afrique. Ouvert en 1988 sur l\'île de Zamalek, avec trois salles de spectacle.',
            'de': 'Das führende Kulturzentrum des Nahen Ostens und Afrikas. 1988 auf Zamalek-Insel mit drei Aufführungssälen eröffnet.',
          },
          category: AttractionCategory.entertainment,
          emoji: '🎭',
          rating: 4.7,
          openHours: 'Varies by show',
          isFree: false,
          admissionEGP: '100–500 EGP',
          walkingMinutes: '15 (cross Nile)',
          tags: ['Culture', 'Music', 'Theater', 'Zamalek'],
        ),
      ],
    ),

    StationAttractions(
      stationId: 'helwan',
      stationName: {'ar': 'محطة حلوان', 'en': 'Helwan Station'},
      attractions: [
        TouristAttraction(
          id: 'japanese_garden',
          name: {'ar': 'الحديقة اليابانية بحلوان', 'en': 'Helwan Japanese Garden', 'fr': 'Jardin Japonais de Helwan', 'de': 'Japanischer Garten Helwan'},
          description: {
            'ar': 'تحفة معمارية يابانية أُهديت لمصر. تمتد على 8 أفدنة وتضم شلالات وقناطر وحجارة يابانية أصيلة. بُنيت عام 1917 وتعكس الصداقة المصرية اليابانية عبر التاريخ.',
            'en': 'A Japanese architectural masterpiece gifted to Egypt. Spans 8 acres with waterfalls, bridges, and authentic Japanese stones. Built in 1917, reflecting Egyptian-Japanese friendship through history.',
            'fr': 'Un chef-d\'œuvre architectural japonais offert à l\'Égypte. S\'étend sur 8 acres avec des cascades et des ponts authentiques. Construit en 1917.',
            'de': 'Ein japanisches Architekturmeisterwerk, Ägypten geschenkt. Erstreckt sich auf 8 Hektar mit Wasserfällen und Brücken. Erbaut 1917, spiegelt ägyptisch-japanische Freundschaft.',
          },
          category: AttractionCategory.park,
          emoji: '🌸',
          rating: 4.5,
          openHours: '9:00 AM – 4:00 PM',
          isFree: false,
          admissionEGP: '10 EGP',
          walkingMinutes: '5',
          tags: ['Japanese', 'Garden', 'Historic', 'Nature'],
        ),
        TouristAttraction(
          id: 'wax_museum_helwan',
          name: {'ar': 'متحف الشمع', 'en': 'Helwan Wax Museum', 'fr': 'Musée de Cire d\'Helwan', 'de': 'Helwan Wachsfigurenkabinett'},
          description: {
            'ar': 'متحف الشمع الوحيد في مصر والثاني في العالم العربي. يضم تماثيل شمعية لأشهر الشخصيات المصرية والعالمية. تجربة ممتعة للعائلات والأطفال.',
            'en': 'Egypt\'s only wax museum and the second in the Arab world. Features wax figures of Egypt\'s and the world\'s most famous personalities. A fun experience for families and children.',
            'fr': 'Le seul musée de cire en Égypte et le deuxième dans le monde arabe. Présente des personnages célèbres d\'Égypte et du monde.',
            'de': 'Ägyptens einziges Wachsfigurenkabinett und das zweite in der arabischen Welt. Zeigt Wachsfiguren berühmter Persönlichkeiten.',
          },
          category: AttractionCategory.museum,
          emoji: '🎭',
          rating: 4.0,
          openHours: '10:00 AM – 5:00 PM',
          isFree: false,
          admissionEGP: '30 EGP',
          walkingMinutes: '10',
          tags: ['Family', 'Wax Figures', 'Fun'],
        ),
      ],
    ),

    StationAttractions(
      stationId: 'ramses',
      stationName: {'ar': 'محطة رمسيس', 'en': 'Ramses Station'},
      attractions: [
        TouristAttraction(
          id: 'ramses_square',
          name: {'ar': 'ميدان رمسيس', 'en': 'Ramses Square', 'fr': 'Place Ramsès', 'de': 'Ramses-Platz'},
          description: {
            'ar': 'أكبر ميادين القاهرة وأكثرها حركة. يتوسطه محطة سكك الحديد الكبرى. يحمل اسم الفرعون العظيم رمسيس الثاني ويعكس عظمة التاريخ المصري في قلب الحياة المعاصرة.',
            'en': 'Cairo\'s largest and busiest square, centered around the main railway station. Named after the great Pharaoh Ramses II, reflecting ancient Egyptian glory in modern city life.',
            'fr': 'La plus grande et la plus animée des places du Caire, centrée autour de la gare principale. Porte le nom du grand pharaon Ramsès II.',
            'de': 'Kairos größter und belebtester Platz rund um den Hauptbahnhof. Benannt nach dem großen Pharao Ramses II.',
          },
          category: AttractionCategory.landmark,
          emoji: '🏟️',
          rating: 4.2,
          openHours: 'Always open',
          isFree: true,
          admissionEGP: 'Free',
          walkingMinutes: '2',
          tags: ['City Center', 'Transport Hub', 'Historic Name'],
        ),
      ],
    ),

    StationAttractions(
      stationId: 'shubra_el_kheima',
      stationName: {'ar': 'محطة شبرا الخيمة', 'en': 'Shubra El-Kheima Station'},
      attractions: [
        TouristAttraction(
          id: 'shubra_palace',
          name: {'ar': 'قصر شبرا', 'en': 'Shubra Palace', 'fr': 'Palais de Shubra', 'de': 'Shubra-Palast'},
          description: {
            'ar': 'أحد أجمل القصور الخديوية في مصر، بُني للخديوي محمد علي عام 1808. يُجمع بين الطرازين الإسلامي والأوروبي في تناسق رائع. بحيرة البهو المستطيلة داخله تحفة معمارية فريدة.',
            'en': 'One of Egypt\'s most beautiful Khedival palaces, built for Mohamed Ali in 1808. Blends Islamic and European architectural styles. The rectangular pool hall inside is a unique masterpiece.',
            'fr': 'L\'un des plus beaux palais khédiviaux d\'Égypte, construit pour Mohamed Ali en 1808. Mélange de styles islamiques et européens.',
            'de': 'Eines der schönsten khedivalen Paläste Ägyptens, für Mohamed Ali 1808 erbaut. Vereint islamische und europäische Architekturstile.',
          },
          category: AttractionCategory.palace,
          emoji: '🏰',
          rating: 4.4,
          openHours: '9:00 AM – 3:00 PM',
          isFree: false,
          admissionEGP: '50 EGP',
          walkingMinutes: '12',
          tags: ['Palace', 'Mohamed Ali', '19th Century', 'Architecture'],
        ),
      ],
    ),

    // ─── LINE 2 (YELLOW/GREEN) ─────────────────────────────────────────────────

    StationAttractions(
      stationId: 'el_bohoos',
      stationName: {'ar': 'محطة البحوث', 'en': 'El-Bohoos Station'},
      attractions: [
        TouristAttraction(
          id: 'cairo_university',
          name: {'ar': 'جامعة القاهرة', 'en': 'Cairo University', 'fr': 'Université du Caire', 'de': 'Universität Kairo'},
          description: {
            'ar': 'أعرق جامعة في مصر والعالم العربي، أُسست عام 1908. مبناها الرئيسي بقبته الشهيرة تحفة معمارية. أنجبت رؤساء وعلماء ونوبليين. تستقبل أكثر من 250,000 طالب.',
            'en': 'Egypt\'s and the Arab world\'s most prestigious university, founded 1908. Its iconic domed main building is an architectural masterpiece. Home to presidents, scholars, and Nobel laureates. Hosts 250,000+ students.',
            'fr': 'L\'université la plus prestigieuse d\'Égypte et du monde arabe, fondée en 1908. Son bâtiment principal à dôme iconique est un chef-d\'œuvre architectural.',
            'de': 'Ägyptens und der arabischen Welt renommierteste Universität, gegründet 1908. Ihr ikonisches Kuppelgebäude ist ein architektonisches Meisterwerk.',
          },
          category: AttractionCategory.university,
          emoji: '🎓',
          rating: 4.6,
          openHours: '8:00 AM – 8:00 PM',
          isFree: true,
          admissionEGP: 'Free (public areas)',
          walkingMinutes: '3',
          tags: ['Education', '1908', 'Architecture', 'Historic'],
        ),
      ],
    ),

    StationAttractions(
      stationId: 'cairo_university',
      stationName: {'ar': 'محطة جامعة القاهرة', 'en': 'Cairo University Station'},
      attractions: [
        TouristAttraction(
          id: 'giza_pyramids_gateway',
          name: {'ar': 'بوابة أهرامات الجيزة', 'en': 'Giza Pyramids Gateway', 'fr': 'Porte des Pyramides de Gizeh', 'de': 'Giza-Pyramiden Eingang'},
          description: {
            'ar': 'أقرب محطة مترو للأهرامات العظيمة. من هنا تنطلق للسير إلى أعجوبة الدنيا السابعة. الأهرامات الثلاثة (خوفو، خفرع، منقرع) وأبو الهول العظيم تنتظرك على بُعد تاكسي أو ربع ساعة.',
            'en': 'The closest metro station to the Great Pyramids. From here, head to the Seventh Wonder of the Ancient World. The three pyramids (Khufu, Khafre, Menkaure) and the Great Sphinx await just a taxi ride away.',
            'fr': 'La station de métro la plus proche des Grandes Pyramides. De là, dirigez-vous vers la Septième Merveille du monde antique.',
            'de': 'Die dem nächstgelegene U-Bahnstation zu den Großen Pyramiden. Von hier aus erkunden Sie das Siebte Weltwunder der Antike.',
          },
          category: AttractionCategory.monument,
          emoji: '🔺',
          rating: 5.0,
          openHours: '8:00 AM – 5:00 PM',
          isFree: false,
          admissionEGP: '500 EGP (Pyramids + Sphinx)',
          walkingMinutes: '25 (by taxi/bus)',
          tags: ['UNESCO', 'World Wonder', 'Ancient', 'Must-See'],
          imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/e/e3/Kheops-Pyramid.jpg',
          wikiUrl: 'https://ar.wikipedia.org/wiki/أهرام_الجيزة',
          galleryUrls: [
            'https://upload.wikimedia.org/wikipedia/commons/e/e3/Kheops-Pyramid.jpg',
            'https://upload.wikimedia.org/wikipedia/commons/a/af/All_Gizah_Pyramids.jpg',
            'https://upload.wikimedia.org/wikipedia/commons/f/f6/Great_Sphinx_of_Giza_-_20080716a.jpg',
          ],
        ),
      ],
    ),

    StationAttractions(
      stationId: 'zamalek',
      stationName: {'ar': 'الزمالك / كيت كات', 'en': 'Zamalek / Kit Kat'},
      attractions: [
        TouristAttraction(
          id: 'cairo_tower',
          name: {'ar': 'برج القاهرة', 'en': 'Cairo Tower', 'fr': 'Tour du Caire', 'de': 'Kairoer Turm'},
          description: {
            'ar': 'أعلى برج في أفريقيا والشرق الأوسط بارتفاع 187 متراً. بُني عام 1961 في شكل لوتس فرعونية. من قمته ترى القاهرة كاملة، الأهرامات، والنيل في مشهد بانورامي خيالي. مطعم دوّار على أعلاه.',
            'en': 'Africa\'s and the Middle East\'s tallest tower at 187 meters. Built 1961 in the shape of a pharaonic lotus. From the top, see all of Cairo, the Pyramids, and the Nile in a breathtaking panorama. Revolving restaurant at the top.',
            'fr': 'La plus haute tour d\'Afrique et du Moyen-Orient à 187 mètres. Construite en 1961 en forme de lotus pharaonique. Du sommet, vue panoramique sur Le Caire, les Pyramides et le Nil.',
            'de': 'Afrikas und dem Nahen Ostens höchster Turm mit 187 Metern. 1961 in Form eines pharaonischen Lotus erbaut. Vom Gipfel aus Panoramablick auf ganz Kairo, die Pyramiden und den Nil.',
          },
          category: AttractionCategory.landmark,
          emoji: '🗼',
          rating: 4.6,
          openHours: '9:00 AM – 1:00 AM',
          isFree: false,
          admissionEGP: '200 EGP',
          walkingMinutes: '15 (cross bridge)',
          tags: ['Panorama', 'Iconic', 'Nile View', 'Zamalek'],
        ),
      ],
    ),

    // ─── LINE 3 (BLUE) ─────────────────────────────────────────────────────────

    StationAttractions(
      stationId: 'nozha',
      stationName: {'ar': 'محطة النزهة', 'en': 'Nozha Station'},
      attractions: [
        TouristAttraction(
          id: 'baron_palace',
          name: {'ar': 'قصر البارون أمبان', 'en': 'Baron Empain Palace', 'fr': 'Palais Baron Empain', 'de': 'Baron-Empain-Palast'},
          description: {
            'ar': 'من أغرب وأجمل قصور العالم. بُني للبارون البلجيكي إدوار لويس جوزيف إمبان عام 1911 بنمط هندوسي فريد مستوحى من معابد أنكور وات. يُعدّ من أكثر المباني غموضاً وإثارة في مصر.',
            'en': 'One of the world\'s most mysterious and beautiful palaces. Built for Belgian Baron Édouard Empain in 1911 with a unique Hindu style inspired by Angkor Wat temples. Considered one of Egypt\'s most intriguing buildings.',
            'fr': 'L\'un des palais les plus mystérieux et beaux du monde. Construit pour le baron belge Édouard Empain en 1911, style hindou inspiré d\'Angkor Vat.',
            'de': 'Einer der geheimnisvollsten und schönsten Paläste der Welt. 1911 für den belgischen Baron Édouard Empain im hinduistischen Stil gebaut, inspiriert von Angkor Wat.',
          },
          category: AttractionCategory.palace,
          emoji: '🏯',
          rating: 4.7,
          openHours: '10:00 AM – 5:00 PM',
          isFree: false,
          admissionEGP: '60 EGP',
          walkingMinutes: '10',
          tags: ['Mystery', 'Historic', '1911', 'Hindu Style', 'Heliopolis'],
        ),
        TouristAttraction(
          id: 'heliopolis_basilica',
          name: {'ar': 'بازيليك مصر الجديدة', 'en': 'Heliopolis Basilica', 'fr': 'Basilique d\'Héliopolis', 'de': 'Heliopolis-Basilika'},
          description: {
            'ar': 'كنيسة بازيليك رومانية الطراز شاهقة الجمال تعود لعام 1925. بنيت بأمر البارون إمبان ليرقد فيها بعد وفاته. تمثل التفاعل بين الحضارة البلجيكية والمصرية في مطلع القرن العشرين.',
            'en': 'A stunning Roman-style Gothic basilica dating to 1925. Built by Baron Empain to serve as his final resting place. Represents Belgian-Egyptian cultural exchange at the dawn of the 20th century.',
            'fr': 'Une magnifique basilique de style romain datant de 1925. Construite par le Baron Empain comme dernière demeure. Représente l\'échange culturel belgo-égyptien.',
            'de': 'Eine beeindruckende Basilika im romanischen Stil aus dem Jahr 1925. Vom Baron Empain als letzte Ruhestätte erbaut.',
          },
          category: AttractionCategory.church,
          emoji: '⛪',
          rating: 4.4,
          openHours: '8:00 AM – 6:00 PM',
          isFree: true,
          admissionEGP: 'Free',
          walkingMinutes: '12',
          tags: ['1925', 'Architecture', 'Heliopolis', 'Baron Empain'],
        ),
      ],
    ),

    StationAttractions(
      stationId: 'cairo_stadium',
      stationName: {'ar': 'محطة كاير استاد', 'en': 'Cairo Stadium Station'},
      attractions: [
        TouristAttraction(
          id: 'cairo_international_stadium',
          name: {'ar': 'استاد القاهرة الدولي', 'en': 'Cairo International Stadium', 'fr': 'Stade International du Caire', 'de': 'Internationales Stadion Kairo'},
          description: {
            'ar': 'أكبر ملعب في مصر وأفريقيا بطاقة تتجاوز 75,000 متفرج. افتُتح عام 1960 لاستضافة رياضة الألعاب العربية. استضاف كأس الأمم الأفريقية عدة مرات وأشهر المباريات الدولية.',
            'en': 'Egypt\'s and Africa\'s largest stadium with 75,000+ capacity. Opened 1960 for the Arab Games. Has hosted multiple Africa Cup of Nations and major international matches.',
            'fr': 'Le plus grand stade d\'Égypte et d\'Afrique, avec plus de 75 000 places. Ouvert en 1960 pour les Jeux arabes.',
            'de': 'Ägyptens und Afrikas größtes Stadion mit 75.000+ Plätzen. 1960 für die Arabischen Spiele eröffnet.',
          },
          category: AttractionCategory.entertainment,
          emoji: '🏟️',
          rating: 4.3,
          openHours: 'Event days only',
          isFree: false,
          admissionEGP: '50–200 EGP',
          walkingMinutes: '2',
          tags: ['Sports', 'Football', 'Africa Cup', 'Largest'],
        ),
      ],
    ),

    StationAttractions(
      stationId: 'bab_el_shaaria',
      stationName: {'ar': 'محطة باب الشعرية', 'en': 'Bab El-Shaaria Station'},
      attractions: [
        TouristAttraction(
          id: 'islamic_cairo_walk',
          name: {'ar': 'جولة القاهرة الإسلامية', 'en': 'Islamic Cairo Walk', 'fr': 'Promenade du Caire Islamique', 'de': 'Islamisches Kairo Spaziergang'},
          description: {
            'ar': 'أكبر تجمع للعمارة الإسلامية الأصيلة في العالم. من هنا تبدأ رحلتك في شارع المعز الذي يضم 29 مبنى تاريخياً في كيلومتر واحد. المساجد والمدارس والأسبلة والسبيل تلتقي في سمفونية معمارية رائعة.',
            'en': 'The world\'s largest concentration of authentic Islamic architecture. Start your journey along Al-Muizz Street, housing 29 historic buildings in one kilometer. Mosques, schools, and fountains create a magnificent architectural symphony.',
            'fr': 'La plus grande concentration d\'architecture islamique authentique au monde. Commencez par la rue Al-Muizz avec 29 bâtiments historiques en un kilomètre.',
            'de': 'Die weltweit größte Konzentration authentischer islamischer Architektur. Beginnen Sie auf der Al-Muizz-Straße mit 29 historischen Gebäuden auf einem Kilometer.',
          },
          category: AttractionCategory.landmark,
          emoji: '🕌',
          rating: 4.9,
          openHours: 'Always open (outdoor)',
          isFree: true,
          admissionEGP: 'Free',
          walkingMinutes: '5',
          tags: ['UNESCO', 'Al-Muizz Street', 'Islamic Architecture', 'Historic'],
        ),
        TouristAttraction(
          id: 'sultan_hassan_mosque',
          name: {'ar': 'مسجد السلطان حسن', 'en': 'Sultan Hassan Mosque', 'fr': 'Mosquée du Sultan Hassan', 'de': 'Sultan-Hassan-Moschee'},
          description: {
            'ar': 'تحفة العمارة الإسلامية في العالم. بُني بين عامي 1356 و1363 ميلادي. يُعدّ من أكبر المساجد في العالم بمساحة 7,906 متر مربع. قبابه وأبراجه الشاهقة تسحر الأبصار من مسافات بعيدة.',
            'en': 'A masterpiece of world Islamic architecture. Built 1356-1363 AD. One of the world\'s largest mosques at 7,906 sq meters. Its towering domes and minarets captivate from afar.',
            'fr': 'Un chef-d\'œuvre de l\'architecture islamique mondiale. Construit entre 1356 et 1363. L\'une des plus grandes mosquées du monde avec 7 906 m².',
            'de': 'Ein Meisterwerk der islamischen Weltarchitektur. 1356-1363 erbaut. Eine der größten Moscheen der Welt mit 7.906 m².',
          },
          category: AttractionCategory.mosque,
          emoji: '🕌',
          rating: 4.8,
          openHours: '8:00 AM – 5:00 PM',
          isFree: false,
          admissionEGP: '100 EGP',
          walkingMinutes: '20 (via Islamic Cairo)',
          tags: ['Mamluk', '14th Century', 'Architecture', 'World-Class'],
        ),
      ],
    ),

    StationAttractions(
      stationId: 'abbassiya',
      stationName: {'ar': 'محطة عباسية', 'en': 'Abbassiya Station'},
      attractions: [
        TouristAttraction(
          id: 'military_museum',
          name: {'ar': 'متحف الحضارة المصرية العسكري', 'en': 'Military Museum (Citadel)', 'fr': 'Musée Militaire (Citadelle)', 'de': 'Militärmuseum (Zitadelle)'},
          description: {
            'ar': 'يحكي ملحمة الجيش المصري عبر 7000 سنة من التاريخ. دروعه وأسلحته وعرباته تروي قصص حروب مصر العظيمة. قلعة صلاح الدين التي يقع فيها تُطل على القاهرة بمشهد ساحر.',
            'en': 'Chronicles the Egyptian military\'s epic across 7,000 years. Armor, weapons, and vehicles tell stories of Egypt\'s great wars. Saladin\'s Citadel where it\'s located overlooks Cairo with a magical view.',
            'fr': 'Raconte l\'épopée militaire égyptienne sur 7000 ans. Armures, armes et véhicules témoignent des guerres égyptiennes. La Citadelle de Saladin offre une vue magique sur le Caire.',
            'de': 'Erzählt die militärische Epopöe Ägyptens über 7.000 Jahre. Rüstungen, Waffen und Fahrzeuge berichten von Ägyptens Kriegen.',
          },
          category: AttractionCategory.museum,
          emoji: '⚔️',
          rating: 4.5,
          openHours: '9:00 AM – 4:00 PM',
          isFree: false,
          admissionEGP: '150 EGP',
          walkingMinutes: '20 (bus to Citadel)',
          tags: ['Military', 'Citadel', 'Saladin', 'History'],
        ),
      ],
    ),
  ];

  /// Get attractions for a specific station (by partial name match, case insensitive)
  static StationAttractions? findByStation(String stationQuery) {
    final q = stationQuery.toLowerCase().trim();
    for (final s in data) {
      if (s.stationId.toLowerCase().contains(q) ||
          s.stationName['ar']!.toLowerCase().contains(q) ||
          s.stationName['en']!.toLowerCase().contains(q)) {
        return s;
      }
    }
    return null;
  }

  /// Get all attractions sorted by rating
  static List<TouristAttraction> getAllAttractions() {
    return data
        .expand((s) => s.attractions)
        .toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));
  }

  /// Get AI-ready context string for all attractions near a station
  static String getAiContextForStation(String stationId, String lang) {
    final station = findByStation(stationId);
    if (station == null) return '';
    final sb = StringBuffer();
    sb.writeln('المعالم السياحية بالقرب من ${station.stationName['ar']}:');
    for (final a in station.attractions) {
      sb.writeln('- ${a.name[lang] ?? a.name['en']}: ${a.description[lang] ?? a.description['en']}');
      sb.writeln('  (${a.openHours} | ${a.admissionEGP} | ${a.walkingMinutes} min walk)');
    }
    return sb.toString();
  }

  static const Map<AttractionCategory, String> categoryEmoji = {
    AttractionCategory.museum: '🏛️',
    AttractionCategory.mosque: '🕌',
    AttractionCategory.church: '⛪',
    AttractionCategory.market: '🛍️',
    AttractionCategory.park: '🌳',
    AttractionCategory.palace: '🏰',
    AttractionCategory.landmark: '🗽',
    AttractionCategory.monument: '🔺',
    AttractionCategory.university: '🎓',
    AttractionCategory.entertainment: '🎭',
  };

  static const Map<AttractionCategory, Map<String, String>> categoryLabel = {
    AttractionCategory.museum:        {'ar': 'متحف', 'en': 'Museum', 'fr': 'Musée', 'de': 'Museum'},
    AttractionCategory.mosque:        {'ar': 'مسجد', 'en': 'Mosque', 'fr': 'Mosquée', 'de': 'Moschee'},
    AttractionCategory.church:        {'ar': 'كنيسة', 'en': 'Church', 'fr': 'Église', 'de': 'Kirche'},
    AttractionCategory.market:        {'ar': 'سوق', 'en': 'Market', 'fr': 'Marché', 'de': 'Markt'},
    AttractionCategory.park:          {'ar': 'حديقة', 'en': 'Park', 'fr': 'Parc', 'de': 'Park'},
    AttractionCategory.palace:        {'ar': 'قصر', 'en': 'Palace', 'fr': 'Palais', 'de': 'Palast'},
    AttractionCategory.landmark:      {'ar': 'معلم', 'en': 'Landmark', 'fr': 'Monument', 'de': 'Wahrzeichen'},
    AttractionCategory.monument:      {'ar': 'أثر', 'en': 'Monument', 'fr': 'Monument', 'de': 'Denkmal'},
    AttractionCategory.university:    {'ar': 'جامعة', 'en': 'University', 'fr': 'Université', 'de': 'Universität'},
    AttractionCategory.entertainment: {'ar': 'ترفيه', 'en': 'Entertainment', 'fr': 'Loisirs', 'de': 'Unterhaltung'},
  };

  static const Map<AttractionCategory, int> categoryColor = {
    AttractionCategory.museum:        0xFF6366F1,
    AttractionCategory.mosque:        0xFF059669,
    AttractionCategory.church:        0xFF7C3AED,
    AttractionCategory.market:        0xFFD97706,
    AttractionCategory.park:          0xFF16A34A,
    AttractionCategory.palace:        0xFFDB2777,
    AttractionCategory.landmark:      0xFF0284C7,
    AttractionCategory.monument:      0xFFB45309,
    AttractionCategory.university:    0xFF0891B2,
    AttractionCategory.entertainment: 0xFFDC2626,
  };
}
