//
//  MapKeyframeView.swift
//  Keyframes
//
//  Created by Jacob Bartlett on 01/08/2025.
//

import MapKit
import SwiftUI

struct MapKeyframeView: View {
    @StateObject private var pubService = PubService()
    @State private var scene: MKLookAroundScene?
    @State private var mapStyle: MapStyle = .standard
    
    var body: some View {
        Map(position: $pubService.cameraPosition) {
            circleLine
            mapAnnotations
        }
        .mapStyle(mapStyle)
        .ignoresSafeArea()
        .onChange(of: pubService.selectedPub) { _, pub in
            if let pub {
                Task {
                    scene = try? await fetchScene(for: pub)
                }
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(1))
            mapStyle = .hybrid(elevation: .realistic)
        }
        .overlay(alignment: .topLeading) {
            backButton
        }
        .overlay(alignment: .bottomLeading) {
            nextPubButton
        }
        .overlay(alignment: .bottomTrailing) {
            lookAroundPreview
        }
        .mapCameraKeyframeAnimator(trigger: pubService.selectedPub, keyframes: { camera in
            KeyframeTrack(\.centerCoordinate) {
                CubicKeyframe(pubService.selectedPub?.coordinate ?? PubService.Constants.london,
                              duration: ((pubService.previousPub == nil) || (pubService.selectedPub == nil)) ? 1 : 6)
            }
            KeyframeTrack(\.distance) {
                if pubService.previousPub == nil {
                    CubicKeyframe(pubService.selectedPub == nil ? 12_000 : 4_000, duration: 1)
                } else if pubService.selectedPub == nil {
                    CubicKeyframe(12_000, duration: 1)
                } else {
                    CubicKeyframe(600, duration: 2)
                    LinearKeyframe(600, duration: 3)
                    SpringKeyframe(4_000, duration: 1)
                }
            }
            KeyframeTrack(\.pitch) {
                if pubService.previousPub != nil && pubService.selectedPub != nil {
                    LinearKeyframe(45, duration: 2.5)
                    LinearKeyframe(0, duration: 2.5)
                } else {
                    LinearKeyframe(0, duration: 1)
                }
            }
        })
    }
    
    private var circleLine: some MapContent {
        MapPolyline(
            coordinates: pubService.pubs.map(\.coordinate) + [pubService.pubs.first?.coordinate].compactMap{ $0 },
            contourStyle: .geodesic
        )
        .mapOverlayLevel(level: .aboveRoads)
        .stroke(.yellow, style: .init(lineWidth: 4))
    }
    
    private var mapAnnotations: some MapContent {
        ForEach(pubService.pubs, id: \.stop) { pub in
            Annotation("\(pub.pubName)\n(\(pub.station))", coordinate: pub.coordinate) {
                Button(action: {
                    pubService.select(pub: pub)
                }, label: {
                    PubAnnotationView(pub: pub,
                                      isSelected: (pubService.selectedPub?.stop == pub.stop))
                    .buttonStyle(.plain)
                })
                .animation(.bouncy, value: pubService.selectedPub)
            }
        }
    }
    
    @ViewBuilder
    private var backButton: some View {
        if pubService.selectedPub != nil {
            Button(action: {
                pubService.deselect()
            }, label: {
                ZStack {
                    Circle()
                        .foregroundStyle(.blue)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "arrow.backward")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
            })
            .padding()
        }
    }
    
    @ViewBuilder
    private var lookAroundPreview: some View {
        if pubService.selectedPub != nil {
            LookAroundPreview(scene: $scene, allowsNavigation: true, badgePosition: .bottomTrailing)
                .frame(width: 180, height: 180)
                .clipShape(Circle())
        }
    }
    
    private var nextPubButton: some View {
        Button(action: {
            pubService.selectNext()
        }, label: {
            ZStack {
                Circle()
                    .fill(Color.green)
                    .frame(width: 80, height: 80)
                
                VStack(spacing: 6) {
                    Image(systemName: "forward.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    Text("Next Pub")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                }
            }
        })
        .padding()
    }
    
    private func fetchScene(for pub: Pub) async throws -> MKLookAroundScene? {
        let lookAroundScene = MKLookAroundSceneRequest(coordinate: pub.coordinate)
        return try await lookAroundScene.scene
    }
}

struct Pub: Codable, Equatable {
    let stop: Int
    let pubName: String
    let station: String
    let description: String
    let address: String
    let coordinate: CLLocationCoordinate2D
    
    enum CodingKeys: String, CodingKey {
        case stop
        case pubName
        case station
        case description
        case address
        case coordinate
    }
    
    enum CoordinateKeys: String, CodingKey {
        case latitude
        case longitude
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(stop, forKey: .stop)
        try container.encode(pubName, forKey: .pubName)
        try container.encode(station, forKey: .station)
        try container.encode(description, forKey: .description)
        try container.encode(address, forKey: .address)
        
        var coordinateContainer = container.nestedContainer(keyedBy: CoordinateKeys.self, forKey: .coordinate)
        try coordinateContainer.encode(coordinate.latitude, forKey: .latitude)
        try coordinateContainer.encode(coordinate.longitude, forKey: .longitude)
    }
    
    var visited: Bool = false
    
    static func ==(lhs: Pub, rhs: Pub) -> Bool {
        lhs.stop == rhs.stop
    }
    
    init(stop: Int, pubName: String, station: String, description: String, address: String, coordinate: CLLocationCoordinate2D, visited: Bool = false) {
        self.stop = stop
        self.pubName = pubName
        self.station = station
        self.description = description
        self.address = address
        self.coordinate = coordinate
        self.visited = visited
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        stop = try container.decode(Int.self, forKey: .stop)
        pubName = try container.decode(String.self, forKey: .pubName)
        station = try container.decode(String.self, forKey: .station)
        description = try container.decode(String.self, forKey: .description)
        address = try container.decode(String.self, forKey: .address)
        
        let coordinateContainer = try container.nestedContainer(keyedBy: CoordinateKeys.self, forKey: .coordinate)
        let lat = try coordinateContainer.decode(CLLocationDegrees.self, forKey: .latitude)
        let lon = try coordinateContainer.decode(CLLocationDegrees.self, forKey: .longitude)
        coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}

final class PubService: ObservableObject {
    @Published var cameraPosition: MapCameraPosition
    @Published private(set) var pubs: [Pub] = []
    @Published private(set) var selectedPub: Pub?
    @Published private(set) var previousPub: Pub?
    
    private var currentIndex: Int = 0
    
    enum Constants {
        static let london = CLLocationCoordinate2D(latitude: 51.5077, longitude: -0.1300)
    }
    
    let defaultCamera: MapCamera = MapCamera(
        centerCoordinate: Constants.london,
        distance: 12_000,
        heading: .zero
    )
    
    init() {
        cameraPosition = .camera(defaultCamera)
        loadPubCrawl()
    }
    
    func select(pub: Pub) {
        previousPub = selectedPub
        selectedPub = pub
        // Update current index to match selected pub
        if let index = pubs.firstIndex(where: { $0.stop == pub.stop }) {
            currentIndex = index
        }
    }
    
    func deselect() {
        previousPub = selectedPub
        selectedPub = nil
    }
    
    func selectNext() {
        guard !pubs.isEmpty else { return }
        
        // If no pub is currently selected, start with the first one
        if selectedPub == nil {
            currentIndex = 0
        } else {
            // Move to next pub, wrapping around to first if at end
            currentIndex = (currentIndex + 1) % pubs.count
        }
        
        let nextPub = pubs[currentIndex]
        select(pub: nextPub)
    }
    
    private func loadPubCrawl() {
        // Embedded pub data since we can't easily copy the JSON file
        let pubsData = """
        [
            {
                "pubName": "The Shakespeare",
                "description": "The Shakespeare is a large, historic pub near Victoria Station. It once had the longest bar counter in London! A Greene King pub serving its own beers and guest ales like Timothy Taylor.",
                "station": "Victoria",
                "coordinate": {
                    "longitude": -0.144825,
                    "latitude": 51.4962508
                },
                "address": "99 Buckingham Palace Rd, London SW1W 0RP",
                "stop": 1
            },
            {
                "description": "Recently refurbished and spread over three floors, The Old Star is filled with London Underground memorabilia. It’s a Greene King pub, offering classic beers and real ales.",
                "address": "66 Broadway, London SW1H 0DB",
                "coordinate": {
                    "longitude": -0.1337106,
                    "latitude": 51.4999398
                },
                "stop": 2,
                "pubName": "The Old Star",
                "station":"St. James's Park"
            },
            {
                "coordinate": {
                    "longitude": -0.1255893,
                    "latitude": 51.5012245
                },
                "description":"A Grade-II listed pub opposite Big Ben and The Houses of Parliament. Opened in 1875, it's famous for its historic patrons, including Churchill. Serves Hall & Woodhouse's Badger beers.",
                "address": "10 Bridge St, London SW1A 2JR",
                "pubName":"St Stephen's Tavern",
                "station": "Westminster",
                "stop": 3
            },
            {
                "station": "Embankment",
                "pubName": "The Princess Of Wales",
                "coordinate": {
                    "longitude": -0.123703,
                    "latitude": 51.5082078
                },
                "stop": 4,
                "description": "A Nicholson’s pub near Charing Cross, known for its historic decor and changing cask ales. Named after King George IV’s secret first wife.",
                "address": "27 Villiers St, Greater, London WC2N 6ND"
            },
            {
                "stop": 5,
                "station": "Temple",
                "coordinate": {
                    "longitude": -0.1129293,
                    "latitude": 51.512954
                },
                "description": "A microbrewery and home to Essex Street Brewing Company. Offers fresh pints brewed on-site, with a unique and cozy atmosphere.",
                "pubName": "Temple Brew House",
                "address": "46 Essex St, Temple, London WC2R 3JF"
            },
            {
                "description": "A stunning Art Nouveau pub built in 1875, located on the site of a Dominican friary. Famous for its unique decor and Nicholson’s selection of cask ales.",
                "pubName": "The Blackfriar",
                "stop": 6,
                "address": "174 Queen Victoria St, Greater, City of London, London EC4V 4EG",
                "coordinate": {
                    "longitude": -0.1037256,
                    "latitude": 51.5121222
                },
                "station": "Blackfriars"
            },
            {
                "address": "29 Watling St, Greater, City of London, London EC4M 9BR",
                "pubName": "Ye Olde Watling",
                "stop": 7,
                "station": "Mansion House",
                "description":"A Nicholson’s pub built using wood from old ships by Christopher Wren. Features a historic back room where plans for St Paul's Cathedral were drawn up.",
                "coordinate": {
                    "longitude": -0.0935681,
                    "latitude": 51.5129545
                }
            },
            {
                "address": "105-109 Cannon St, City of London, London EC4N 5AD",
                "station": "Cannon Street",
                "description": "An underground pub with air conditioning and a large craft beer selection. Known for its rotating beer selection and quirky interior.",
                "pubName": "The Cannick Tapps",
                "coordinate": {
                    "latitude": 51.5115967,
                    "longitude": -0.0896671
                },
                "stop": 8
            },
            {
                "station": "Monument",
                "pubName": "The Monument",
                "stop": 9,
                "address": "18 Fish St Hill, City of London, London EC3R 6DB",
                "description": "A Greene King pub located near the historic Monument to the Great Fire of London. Large space with outdoor seating and a classic pub menu.",
                "coordinate": {
                    "longitude": -0.0862747,
                    "latitude": 51.5100768
                }
            },
            {
                "station": "Tower Hill",
                "stop": 10,
                "description": "A traditional pub under railway arches, featuring a heated beer garden and large TV screens for sports fans.",
                "address": "64-73 Minories, City of London, London EC3N 1LA",
                "coordinate": {
                    "latitude": 51.5105331,
                    "longitude": -0.0744113
                },
                "pubName": "The Minories"
            },
            {
                "coordinate": {
                    "longitude": -0.0741921,
                    "latitude": 51.5142486
                },
                "station": "Aldgate",
                "description": "One of the few timber-framed buildings to survive the Great Fire of London, this pub is full of history and serves craft beers and British pub food.",
                "pubName": "The Hoop and Grapes",
                "stop": 11,
                "address": "47 Aldgate High St, Greater, City of London, London EC3N 1AL"
            },
            {
                "pubName": "Hamilton Hall",
                "coordinate": {
                    "latitude": 51.5175477,
                    "longitude": -0.0829407
                },
                "station": "Liverpool Street",
                "stop": 12,
                "address": "Liverpool St, City of London, London EC2M 7PY",
                "description": "A grand Wetherspoons pub with chandeliers and high ceilings, formerly the ballroom of the Great Eastern Hotel."
            },
            {
                "stop": 13,
                "address": "83 Moorgate, Greater, City of London, London EC2M 6SA",
                "pubName": "The Globe",
                "coordinate": {
                    "latitude": 51.5176697,
                    "longitude": -0.0887354
                },
                "station": "Moorgate",
                "description": "A Nicholson’s pub offering an extensive drink selection, including 20+ gins and a variety of craft ales. Located near the birthplace of poet John Keats."
            },
            {
                "address": "The Shakespeare, 2 Goswell Rd., Golden Lane Estate, London EC1M 7AA",
                "pubName": "The Shakespeare",
                "stop": 14,
                "station": "Barbican",
                "description": "A historic pub that now serves Italian food in collaboration with the renowned La Pia restaurant. Closed on Sundays.",
                "coordinate": {
                    "latitude": 51.5217345,
                    "longitude": -0.0971015
                }
            },
            {
                "description":"A classic pub once used for cockfighting and pawnbroking. Look for the pawnbroker's sign outside, a nod to its unusual history.",
                "stop": 15,
                "station": "Farringdon",
                "address": "34-35 Cowcross St, Greater, London EC1M 6DB",
                "coordinate": {
                    "longitude": -0.1042239,
                    "latitude": 51.5202507
                },
                "pubName": "The Castle"
            },
            {
                "address":"The Parcel Yard, King's Cross, Euston Rd., London N1 9AL",
                "station":"King's Cross",
                "stop": 16,
                "description":"A Fuller's pub inside King's Cross Station, featuring historic architecture and a selection of classic Fuller's beers like London Pride.",
                "pubName": "The Parcel Yard",
                "coordinate": {
                    "longitude": -0.12350749614095112,
                    "latitude": 51.53027897597364
                }
            },
            {
                "station": "Euston Square",
                "description": "A beer lover’s paradise with 28 keg and 15 cask beers. Located in one of the remaining lodges from the old Euston Station.",
                "pubName": "The Euston Tap",
                "address": "190 Euston Rd., London NW1 2EF",
                "coordinate": {
                    "latitude": 51.526973,
                    "longitude": -0.1325322
                },
                "stop": 17
            },
            {
                "coordinate": {
                    "longitude": -0.1439695,
                    "latitude": 51.5233176
                },
                "pubName": "The Albany",
                "description": "A laid-back pub in Fitzrovia, known for its relaxed atmosphere and late-night hours.",
                "station": "Great Portland Street",
                "stop": 18,
                "address": "240 Great Portland St, Greater, London W1W 5QU"
            },
            {
                "station": "Baker Street",
                "stop": 19,
                "description": "A Wetherspoons pub named after the world’s first underground railway, located near Regent’s Park and Madame Tussauds.",
                "address": "Unit 7, Station Approach, Marylebone Rd, London NW1 5LD",
                "coordinate": {
                    "latitude": 51.5211975,
                    "longitude": -0.1648996
                },
                "pubName": "The Metropolitan Bar"
            },
            {
                "pubName": "The Chapel",
                "address": "48 Chapel St, London NW1 5DP",
                "description": "A spacious gastro pub serving freshly cooked food and a wide variety of international drinks.",
                "station": "Edgware Road",
                "stop": 20,
                "coordinate": {
                    "latitude": 51.5198078,
                    "longitude": -0.1663104
                }
            },
            {
                "station": "Paddington",
                "description": "A Greene King pub next to Paddington Station, offering traditional British fare and a familiar selection of drinks.",
                "address": "8 London St, Tyburnia, London W2 1HL",
                "coordinate": {
                    "latitude": 51.5154216,
                    "longitude": -0.1745291
                },
                "stop": 21,
                "pubName": "Sawyers Arms"
            },
            {
                "address": "Queensway, London W2 4QH",
                "coordinate": {
                    "longitude": -0.1875125,
                    "latitude": 51.5122494
                },
                "stop": 22,
                "station": "Bayswater",
                "description": "A Greene King pub located near Kensington Gardens, serving traditional pub food and real ales.",
                "pubName": "Bayswater Arms"
            },
            {
                "coordinate": {
                    "longitude": -0.1950499,
                    "latitude": 51.5089407
                },
                "pubName": "Old Swan",
                "address": "206 Kensington Church St, London W8 4DP",
                "stop": 23,
                "station": "Notting Hill Gate",
                "description": "A spacious Greene King pub that briefly changed its name to The Rat & Parrot before reverting to its original identity."
            },
            {
                "coordinate": {
                    "latitude": 51.499469,
                    "longitude": -0.1954173
                },
                "description": "A cozy pub with leather armchairs and a fireplace, situated on the historic Britannia Brewery site.",
                "address": "1 Allen St, London W8 6UX",
                "stop": 24,
                "station": "High Street Kensington",
                "pubName": "The Britannia"
            },
            {
                "description": "A bright Victorian pub built in the 1800s, named after the Stanhope family, with a classic Greene King menu.",
                "address": "97 Gloucester Rd, South Kensington, London SW7 4SS",
                "coordinate": {
                    "longitude": -0.1821671,
                    "latitude": 51.4941175
                },
                "station": "Gloucester Road",
                "stop": 25,
                "pubName": "The Stanhope Arms"
            },
            {
                "station": "South Kensington",
                "stop": 26,
                "pubName": "Hoop & Toy",
                "description": "A traditional Victorian pub with exposed brick walls, located near the Royal Albert Hall and Victoria & Albert Museum.",
                "address": "34 Thurloe Pl, South Kensington, London SW7 2HQ",
                "coordinate": {
                    "longitude": -0.1741921,
                    "latitude": 51.4946613
                }
            },
            {
                "description": "A historic Belgravia pub with a warm atmosphere, marking the final stop of the Circle Line Pub Crawl.",
                "address": "22 Eaton Terrace, London SW1W 8EZ",
                "coordinate": {
                    "longitude": -0.1554902,
                    "latitude": 51.4940089
                },
                "pubName": "The Antelope",
                "stop": 27,
                "station": "Sloane Square"
            }
        ]

        """.data(using: .utf8)!
        
        do {
            pubs = try JSONDecoder().decode([Pub].self, from: pubsData)
        } catch {
            print("Failed to load pub data: \\(error)")
        }
    }
}

struct PubAnnotationView: View {
    let pub: Pub
    let isSelected: Bool
    
    init(pub: Pub, isSelected: Bool) {
        self.pub = pub
        self.isSelected = isSelected
    }
    
    var body: some View {
        ZStack {
            badge
            icon
        }
        .scaleEffect(isSelected ? 1.8 : 1)
    }
    
    private var badge: some View {
        Circle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.orange.opacity(0.9),
                        Color.yellow.opacity(0.7),
                        Color.orange.opacity(0.9),
                        Color.brown.opacity(0.6)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [.white.opacity(0.8), .clear]),
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 2
                    )
            )
            .shadow(color: .black.opacity(0.2), radius: 3, x: 1, y: 1)
            .frame(width: 30, height: 30)
    }
    
    private var icon: some View {
        ZStack {
            mug
                .foregroundColor(.black.opacity(0.4))
                .offset(x: 1, y: 1)
                .blendMode(.overlay)
            
            mug
                .foregroundColor(.white.opacity(0.6))
                .offset(x: -0.5, y: -0.5)
                .blendMode(.overlay)
            
            mug
                .foregroundColor(Color.white.opacity(0.25))
        }
        .offset(x: 1, y: 0.5)
    }
    
    private var mug: some View {
        Image(systemName: "mug")
            .font(.title3)
    }
}

#Preview {
    MapKeyframeView()
}
