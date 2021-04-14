//
//  BikeMapViewController.swift
//  Bike
//
//  Created by CHIA CHUN LI on 2021/3/16.
//

import UIKit
import GoogleMobileAds
import GoogleMaps
import CoreLocation
import Network



class BikeMapViewController: UIViewController,CLLocationManagerDelegate,GMSMapViewDelegate {

    @IBOutlet weak var bannerView: GADBannerView!
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var updateTimeLabel: UILabel!
    @IBOutlet weak var reloadBtn: UIButton!
    @IBOutlet weak var navigationBtn: UIButton!
    @IBOutlet weak var coverView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var bikeRouteBtn: UIButton!
    
    var locationManager = CLLocationManager()
    var userLocationCounty = ""
    var cityDic = ["臺中市":"Taichung","新竹市":"Hsinchu","苗栗縣":"MiaoliCounty","彰化縣":"ChanghuaCounty","新北市":"NewTaipei","屏東縣":"PingtungCounty","金門縣":"KinmenCounty","桃園市":"Taoyuan","臺北市":"Taipei","高雄市":"Kaohsiung","臺南市":"Tainan"]
    
    var cityName = ""
    var urlString = ""
    
    var stationUIDDic = [String:String]()
    var stationLatDic = [String:Double]()
    var stationLonDic = [String:Double]()
    var stationRentBikesDic = [String:Int]()
    var stationReturnBikesDic = [String:Int]()
    
    var userLocationLat:Double?
    var userLocationLon:Double?
    var selectMarkerLat:Double?
    var selectMarkerLon:Double?
  
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //判斷有無網路
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [self] path in
           
            switch path.status {
            case .satisfied:
                //print("connect")
                
                if CLLocationManager.locationServicesEnabled(){

                    // 首次使用 向使用者詢問定位自身位置權限
                    if locationManager.authorizationStatus
                        == .notDetermined {
                        // 取得定位服務授權
                        locationManager.requestWhenInUseAuthorization()
                        // 開始定位自身位置
                        locationManager.startUpdatingLocation()
                    }
                    // 使用者已經拒絕定位自身位置權限
                    else if locationManager.authorizationStatus
                                == .denied {
                        // 提示可至[設定]中開啟權限
                        DispatchQueue.main.async {
                            let errorAlert = createErrorAlert(alertControllerTitle: "定位權限已關閉", alertActionTitle: "確定", message: "如要變更權限，請至 設定 > 隱私權 > 定位服務 開啟", alertControllerStyle: .alert, alertActionStyle: UIAlertAction.Style.default, viewController: self)
                            self.present(errorAlert, animated: true, completion: nil)
                        }
                        
                    }
                    // 使用者已經同意定位自身位置權限
                    else if locationManager.authorizationStatus
                                == .authorizedWhenInUse {
                        // 開始定位自身位置
                        locationManager.startUpdatingLocation()
                    }

                }else{
                    
                    DispatchQueue.main.async {
                        let errorAlert = createErrorAlert(alertControllerTitle: "定位權限已關閉", alertActionTitle: "確定", message: "如要變更權限，請至 設定 > 隱私權 > 定位服務 開啟", alertControllerStyle: .alert, alertActionStyle: UIAlertAction.Style.default, viewController: self)
                        self.present(errorAlert, animated: true, completion: nil)
                    }
                    

                }
            case .unsatisfied:
                //print("not connect")
                DispatchQueue.main.async {
                    let errorAlert = createErrorAlert(alertControllerTitle: "", alertActionTitle: "確定", message: "網路連線品質不佳", alertControllerStyle: .alert, alertActionStyle: UIAlertAction.Style.default, viewController: self)
                    self.present(errorAlert, animated: true, completion: nil)
                }
            case .requiresConnection:
                //print("not connect")
                DispatchQueue.main.async {
                    let errorAlert = createErrorAlert(alertControllerTitle: "無網路", alertActionTitle: "確定", message: "請連線網路", alertControllerStyle: .alert, alertActionStyle: UIAlertAction.Style.default, viewController: self)
                    self.present(errorAlert, animated: true, completion: nil)
                }
            default:
                break
            }
         
            
        }
        //偵測網路
        monitor.start(queue: DispatchQueue.global())
        //print("網路狀態=\(monitor.currentPath.status)")
        
        
        coverView.isHidden = false
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        
        reloadBtn.addTarget(self, action: #selector(reloadBtnClick(_:)), for: .touchUpInside)
        navigationBtn.addTarget(self, action: #selector(navigationBtnClick(_:)), for: .touchUpInside)
        
        //執行廣告
        bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716"
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
        
        //設定定位精準度
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        //設定代理
        locationManager.delegate = self
      
        //取得使用者座標
        if locationManager.authorizationStatus == .authorizedWhenInUse{
            let userLocation = locationManager.location?.coordinate
            userLocationLat = userLocation!.latitude
            userLocationLon = userLocation!.longitude
        }
        
        //print("lat=\(userLocationLat!)")
        //print("lon=\(userLocationLon!)")
        
        //顯示使用者座標
        mapView.isMyLocationEnabled = true
        //使用者座標按鈕
        mapView.settings.myLocationButton = true
        //指北針
        mapView.settings.compassButton = true
        //設定代理
        mapView.delegate = self
        
        //設定顯示範圍
        let camera = GMSCameraPosition.camera(withLatitude: userLocationLat!, longitude: userLocationLon!, zoom: 16.0)
        mapView.camera = camera
        
            //Google Geooding API用使用者座標取得所在縣市
            urlString = "https://maps.googleapis.com/maps/api/geocode/json?latlng=\( userLocationLat!),\( userLocationLon!)&key=AIzaSyDqkyV8h4eog2sUPXwF3VGenG_BPPFjs7k"
            let url = URL(string: urlString)
            
            URLSession.shared.dataTask(with: url!) { [self] (data, response, error) in

                DispatchQueue.main.async {
                    coverView.isHidden = false
                    activityIndicator.isHidden = false
                    activityIndicator.startAnimating()
                }
                
                
                let httpResponse = response as! HTTPURLResponse
                let statusCode = httpResponse.statusCode
                //print("status code=\(statusCode)")
                if statusCode == 200{

                    do{

                        let jsonData = try JSONSerialization.jsonObject(with: data!, options: []) as! [String:AnyObject]
                        //print("json data=\(jsonData)")
                        let results = jsonData["results"] as! [[String:AnyObject]]
                        let address_components = results[0]["address_components"] as! [[String:AnyObject]]
                        //print("results=\(results)")
                        //print("address_components=\(address_components)")
                        DispatchQueue.main.async {
                            self.titleLabel.text = address_components[4]["long_name"] as? String
                        }
                        
                        //取得所在位置縣市對應的值
                        if self.cityDic.keys.contains(address_components[4]["long_name"] as! String){
                            cityName = cityDic[address_components[4]["long_name"] as! String]!
                            //print("city name=\(String(describing: cityName))")
                            
                            //將值帶入取得該縣市自行車資訊
                            let request = urlStringToRequest(urlString: "https://ptx.transportdata.tw/MOTC/v2/Bike/Station/\(cityName)?$format=JSON")
                            URLSession.shared.dataTask(with: request) { (data, response, error) in

                                do{

                                    let jsonData = try JSONSerialization.jsonObject(with: data!, options: []) as! [[String:AnyObject]]

                                    //print("data count=\(jsonData.count)")
                                    for i in 0..<jsonData.count{

                                        let stationPosition = jsonData[i]["StationPosition"] as! [String:AnyObject]
                                        let lat = stationPosition["PositionLat"] as? Double
                                        let lon = stationPosition["PositionLon"] as? Double

                                        let stationNameDic = jsonData[i]["StationName"] as! [String:AnyObject]
                                        let stationName = stationNameDic["Zh_tw"] as? String
                                        let stationUID = jsonData[i]["StationUID"] as? String

                                        if stationName != "" && lat != nil && lon != nil && stationUID != ""{
                                            
                                            //資料儲存於Dic
                                            stationUIDDic.updateValue(stationUID!, forKey: stationName!)
                                            stationLatDic.updateValue(lat!, forKey: stationName!)
                                            stationLonDic.updateValue(lon!, forKey: stationName!)


                                        }
                                    }
                                    //print("station UID dic=\(stationUIDDic.count)")
                                    //print("station lat dic=\(stationLatDic.count)")
                                    //print("station lon dic=\(stationLonDic.count)")
                                    
                                    //將縣市的值帶入取得即時可借可還數量資訊
                                    let request2 = urlStringToRequest(urlString: "https://ptx.transportdata.tw/MOTC/v2/Bike/Availability/\(cityName)?$format=JSON")
                                    URLSession.shared.dataTask(with: request2) { (data, response, error) in

                                        do{

                                            let jsonData = try JSONSerialization.jsonObject(with: data!, options: []) as! [[String:AnyObject]]

                                            //print("data=\(jsonData.count)")
                                            for i in 0..<jsonData.count{

                                                let stationUID = jsonData[i]["StationUID"] as? String
                                                let rentBikes = jsonData[i]["AvailableRentBikes"] as? Int
                                                let returnBikes = jsonData[i]["AvailableReturnBikes"] as? Int
                                                DispatchQueue.main.async {

                                                    //時間格式轉換顯示
                                                    let dateString = jsonData[0]["UpdateTime"] as? String
                                                    let newDate = GlobalData.dateFormatterConvert(stringFMT:"yyyy-MM-ddTHH:mm:sszzz", toConvertStringFMT: "yyyy-MM-dd HH:mm:ss", dateString: dateString!)
                                                    updateTimeLabel.text = "資料更新時間:" + newDate
                                                }

                                                if rentBikes != nil && returnBikes != nil && stationUID != ""{
                                                    //資料儲存於Dic
                                                    self.stationRentBikesDic.updateValue(rentBikes!, forKey: stationUID!)
                                                    self.stationReturnBikesDic.updateValue(returnBikes!, forKey: stationUID!)
                                                }


                                            }

                                            for key in stationUIDDic.keys{
                                                //取出Dic經緯度建立在Google Map上
                                                DispatchQueue.main.async {
                                                    let position = CLLocationCoordinate2D(latitude: stationLatDic[key]!, longitude: stationLonDic[key]!)
                                                    let marker = GMSMarker(position: position)
                                                    marker.title = key
                                                    marker.icon = UIImage(named: "bike.png")
                                                    marker.map = mapView
                                                }


                                            }
                                            DispatchQueue.main.async {
                                                activityIndicator.stopAnimating()
                                                activityIndicator.isHidden = true
                                                coverView.isHidden = true
                                            }
                                            
    //                                        print("station rent bikes dic count=\(stationRentBikesDic.count)")
    //                                        print("station return bikes dic count=\(stationReturnBikesDic.count)")

                                        }catch{
                                            DispatchQueue.main.async {
                                            let alert = self.createErrorAlert(alertControllerTitle: "錯誤", alertActionTitle: "確定", message: "資料維護", alertControllerStyle: .alert, alertActionStyle: .default, viewController: self)
                                            self.present(alert, animated: true, completion: nil)
                                            }
                                        }

                                    }.resume()


                                }catch{
                                    DispatchQueue.main.async {
                                    let alert = createErrorAlert(alertControllerTitle: "錯誤", alertActionTitle: "確定", message: "資料維護", alertControllerStyle: .alert, alertActionStyle: .default, viewController: self)
                                    self.present(alert, animated: true, completion: nil)
                                    }
                                }

                            }.resume()

                        }else{

                            //取得使用者所在縣市 比對後無該縣市對應之資料
                            DispatchQueue.main.async {
                            let alert = createErrorAlert(alertControllerTitle: "此縣市", alertActionTitle: "確定", message: "無公共自行車", alertControllerStyle: .alert, alertActionStyle: .default, viewController: self)
                            self.present(alert, animated: true, completion: nil)
                            }

                        }


                    }catch{
                        DispatchQueue.main.async {
                        let alert = createErrorAlert(alertControllerTitle: "錯誤", alertActionTitle: "確定", message: "資料維護", alertControllerStyle: .alert, alertActionStyle: .default, viewController: self)
                        self.present(alert, animated: true, completion: nil)
                        }
                    }
                }else{
                    //如果http status code != 200
                    DispatchQueue.main.async {
                        let alert = createErrorAlert(alertControllerTitle: "錯誤", alertActionTitle: "確定", message: "資料維護", alertControllerStyle: .alert, alertActionStyle: .default, viewController: self)
                        self.present(alert, animated: true, completion: nil)

                    }

                }

            }.resume()
        
       
            
        // Do any additional setup after loading the view.
    }
    
    
    
    //錯誤警告視窗
    func createErrorAlert(alertControllerTitle:String, alertActionTitle:String,message:String,alertControllerStyle:UIAlertController.Style, alertActionStyle:UIAlertAction.Style,viewController:UIViewController) -> UIAlertController{

        let alert = UIAlertController(title: alertControllerTitle, message: message, preferredStyle: alertControllerStyle)
        let action = UIAlertAction(title: alertActionTitle, style: alertActionStyle) { (action) in
           
            DispatchQueue.main.async {
                if self.coverView.isHidden == false && self.activityIndicator.isHidden == false{
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.isHidden = true
                    self.coverView.isHidden = true
                }
            }
            
           
        }
        alert.addAction(action)
        
        return alert

    }
    
    //reload data
    @objc func reloadBtnClick(_ sender:UIButton){
   
        if coverView.isHidden == true && activityIndicator.isHidden == true{
            coverView.isHidden = false
            activityIndicator.isHidden = false
            activityIndicator.startAnimating()
        }
        
        stationUIDDic = [String:String]()
        stationLatDic = [String:Double]()
        stationLonDic = [String:Double]()
        stationRentBikesDic = [String:Int]()
        stationReturnBikesDic = [String:Int]()
        
        //print("station UID dic count=\(stationUIDDic.count)")
        //print("station Lat dic count=\(stationLatDic.count)")
        //print("station Lon dic count=\(stationLonDic.count)")
        //print("station Rent Bikes dic count=\(stationRentBikesDic.count)")
        //print("station Return Bike count=\(stationReturnBikesDic.count)")
        
        urlString = "https://maps.googleapis.com/maps/api/geocode/json?latlng=\( userLocationLat!),\( userLocationLon!)&key=AIzaSyDqkyV8h4eog2sUPXwF3VGenG_BPPFjs7k"
        let url = URL(string: urlString)

        URLSession.shared.dataTask(with: url!) { [self] (data, response, error) in

            let httpResponse = response as! HTTPURLResponse
            let statusCode = httpResponse.statusCode
            //print("status code=\(statusCode)")
            if statusCode == 200{

                do{

                    let jsonData = try JSONSerialization.jsonObject(with: data!, options: []) as! [String:AnyObject]
                    //print("json data=\(jsonData)")
                    let results = jsonData["results"] as! [[String:AnyObject]]
                    let address_components = results[0]["address_components"] as! [[String:AnyObject]]
                    //print("results=\(results)")
                    //print("address_components=\(address_components)")
                    DispatchQueue.main.async {
                        self.titleLabel.text = address_components[4]["long_name"] as? String
                    }

                    if self.cityDic.keys.contains(address_components[4]["long_name"] as! String){
                        cityName = cityDic[address_components[4]["long_name"] as! String]!
                        //print("city name=\(String(describing: cityName))")

                        let request = urlStringToRequest(urlString: "https://ptx.transportdata.tw/MOTC/v2/Bike/Station/\(cityName)?$format=JSON")
                        URLSession.shared.dataTask(with: request) { (data, response, error) in

                            do{

                                let jsonData = try JSONSerialization.jsonObject(with: data!, options: []) as! [[String:AnyObject]]

                                //print("data count=\(jsonData.count)")
                                for i in 0..<jsonData.count{

                                    let stationPosition = jsonData[i]["StationPosition"] as! [String:AnyObject]
                                    let lat = stationPosition["PositionLat"] as? Double
                                    let lon = stationPosition["PositionLon"] as? Double

                                    let stationNameDic = jsonData[i]["StationName"] as! [String:AnyObject]
                                    let stationName = stationNameDic["Zh_tw"] as? String
                                    let stationUID = jsonData[i]["StationUID"] as? String

                                    if stationName != "" && lat != nil && lon != nil && stationUID != ""{

                                        stationUIDDic.updateValue(stationUID!, forKey: stationName!)
                                        stationLatDic.updateValue(lat!, forKey: stationName!)
                                        stationLonDic.updateValue(lon!, forKey: stationName!)


                                    }
                                }
                                //print("station UID dic=\(stationUIDDic.count)")
                                //print("station lat dic=\(stationLatDic.count)")
                                //print("station lon dic=\(stationLonDic.count)")

                                let request2 = urlStringToRequest(urlString: "https://ptx.transportdata.tw/MOTC/v2/Bike/Availability/\(cityName)?$format=JSON")
                                URLSession.shared.dataTask(with: request2) { (data, response, error) in

                                    do{

                                        let jsonData = try JSONSerialization.jsonObject(with: data!, options: []) as! [[String:AnyObject]]

                                        //print("data=\(jsonData.count)")
                                        for i in 0..<jsonData.count{

                                            let stationUID = jsonData[i]["StationUID"] as? String
                                            let rentBikes = jsonData[i]["AvailableRentBikes"] as? Int
                                            let returnBikes = jsonData[i]["AvailableReturnBikes"] as? Int
                                            DispatchQueue.main.async {

                                                //時間格式轉換顯示
                                                let dateString = jsonData[0]["UpdateTime"] as? String
                                                let newDate = GlobalData.dateFormatterConvert(stringFMT:"yyyy-MM-ddTHH:mm:sszzz", toConvertStringFMT: "yyyy-MM-dd HH:mm:ss", dateString: dateString!)
                                                updateTimeLabel.text = "資料更新時間:" + newDate
                                            }

                                            if rentBikes != nil && returnBikes != nil && stationUID != ""{
                                                self.stationRentBikesDic.updateValue(rentBikes!, forKey: stationUID!)
                                                self.stationReturnBikesDic.updateValue(returnBikes!, forKey: stationUID!)
                                            }


                                        }

                                        for key in stationUIDDic.keys{

                                            DispatchQueue.main.async {
                                                let position = CLLocationCoordinate2D(latitude: stationLatDic[key]!, longitude: stationLonDic[key]!)
                                                let marker = GMSMarker(position: position)
                                                marker.title = key
                                                marker.icon = UIImage(named: "bike.png")
                                                marker.map = mapView
                                            }


                                        }
                                        DispatchQueue.main.async {
                                            activityIndicator.stopAnimating()
                                            activityIndicator.isHidden = true
                                            coverView.isHidden = true
                                        }

//                                        print("station rent bikes dic count=\(stationRentBikesDic.count)")
//                                        print("station return bikes dic count=\(stationReturnBikesDic.count)")

                                    }catch{
                                        DispatchQueue.main.async {
                                        let alert = self.createErrorAlert(alertControllerTitle: "錯誤", alertActionTitle: "確定", message: "資料維護", alertControllerStyle: .alert, alertActionStyle: .default, viewController: self)
                                        self.present(alert, animated: true, completion: nil)
                                        }
                                    }

                                }.resume()


                            }catch{
                                DispatchQueue.main.async {
                                let alert = createErrorAlert(alertControllerTitle: "錯誤", alertActionTitle: "確定", message: "資料維護", alertControllerStyle: .alert, alertActionStyle: .default, viewController: self)
                                self.present(alert, animated: true, completion: nil)
                                }
                            }

                        }.resume()

                    }else{

                        //取得使用者所在縣市 比對後無該縣市對應之資料
                        DispatchQueue.main.async {
                        let alert = createErrorAlert(alertControllerTitle: "此縣市", alertActionTitle: "確定", message: "無公共自行車", alertControllerStyle: .alert, alertActionStyle: .default, viewController: self)
                        self.present(alert, animated: true, completion: nil)
                        }

                    }


                }catch{
                    DispatchQueue.main.async {
                    let alert = createErrorAlert(alertControllerTitle: "錯誤", alertActionTitle: "確定", message: "資料維護", alertControllerStyle: .alert, alertActionStyle: .default, viewController: self)
                    self.present(alert, animated: true, completion: nil)
                    }
                }
            }else{
                //如果http status code != 200
                DispatchQueue.main.async {
                    let alert = createErrorAlert(alertControllerTitle: "錯誤", alertActionTitle: "確定", message: "資料維護", alertControllerStyle: .alert, alertActionStyle: .default, viewController: self)
                    self.present(alert, animated: true, completion: nil)

                }

            }

        }.resume()
        
    }
    
    //導航
    @objc func navigationBtnClick(_ sender:UIButton){
        
        //print("select lat=\(selectMarkerLat)")
        //print("select lon=\(selectMarkerLon)")
        
        //如果經緯度都不是空值就執行導航
        if selectMarkerLat != nil && selectMarkerLon != nil{
            //輸入使用者經緯度與目的地經緯度執行導航程式
            let url = URL(string: "comgooglemaps://?saddr=\(String(describing: userLocationLat!)),\(String(describing: userLocationLon!))&daddr=\(String(describing: selectMarkerLat!)),\(String(describing: selectMarkerLon!))&directionsmode=driving")
            //使用者如果有裝google map就開啟導航
            if UIApplication.shared.canOpenURL(url!) {
                UIApplication.shared.open(url!, options: [:], completionHandler: nil)
            } else {
                // 若手機沒安裝 Google Map App 則導到 App Store(id443904275 為 Google Map App 的 ID)
                let appStoreGoogleMapURL = URL(string: "itms-apps://itunes.apple.com/app/id585027354")!
                UIApplication.shared.open(appStoreGoogleMapURL, options: [:], completionHandler: nil)
            }
        }else{
            
            let alert = createErrorAlert(alertControllerTitle: "未選取", alertActionTitle: "確定", message: "腳踏車站點", alertControllerStyle: .alert, alertActionStyle: .default, viewController: self)
            self.present(alert, animated: true, completion: nil)
            
        }
            
           
            
//            let url = URL(string: "https://maps.googleapis.com/maps/api/directions/json?origin=\(userLocationLat),\(userLocationLon)&destination=\(selectMarkerLat),\(selectMarkerLon)&key=AIzaSyD_yRIzWaPpzTU3hFxHaa6udnqDKyIq7sw")
//            URLSession.shared.dataTask(with: url!) { (data, response, error) in
//
//                do{
//
//                    let jsonData = try JSONSerialization.jsonObject(with: data!, options: []) as! [String:AnyObject]
//                    //print("json data=\(jsonData)")
//                    let routes = jsonData["routes"] as! [NSDictionary]
//                    for route in routes{
//
//                        let routeOverviewPolyline = route["overview_polyline"] as! [String:AnyObject]
//                        print("route overview polyline=\(routeOverviewPolyline)")
//                        let points = routeOverviewPolyline["points"] as! String
//                        print("point=\(points)")
//                        let path = GMSPath(fromEncodedPath: points)
//                        let polyline = GMSPolyline(path: path)
//                        polyline.map = self.mapView
//
//                    }
//
//
//                }catch{
//
//                }
//
//            }.resume()
            
       
      
    }

    
    //顯示站點資訊
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        //print("select station title=\(mapView.selectedMarker?.title)")
        //print("click")
        let selectTitle = mapView.selectedMarker?.title
        selectMarkerLat = mapView.selectedMarker?.position.latitude ?? 0.0
        selectMarkerLon = mapView.selectedMarker?.position.longitude ?? 0.0
        
        //透過Dic的UID比對該站點的可藉可還數量資訊
        if stationUIDDic.keys.contains(selectTitle ?? "無"){
            let uid = stationUIDDic[selectTitle!]
            let rentBike = String(stationRentBikesDic[uid!]!)
            let returnBike = String(stationReturnBikesDic[uid!]!)
            mapView.selectedMarker?.snippet = "可借:" + rentBike + " " + "可還:" + returnBike
        }
        
    }
    
    //url convert to request
    func urlStringToRequest(urlString:String) -> URLRequest{
        
        let APIUrl = urlString
        let APP_ID = "8374e419a1954a2480ef98dc9420cbe7"
        let APP_KEY = "bE1-AeoXWhSPfKXNujfs0I4iABw"
        
        let xdate:String = GlobalData.getServerTime()
        let signDate = "x-date: " + xdate;
        
        let base64HmacStr = signDate.hmac(algorithm: .SHA1, key: APP_KEY)
        let authorization:String = "hmac username=\""+APP_ID+"\", algorithm=\"hmac-sha1\", headers=\"x-date\", signature=\""+base64HmacStr+"\""
        
        let url = URL(string: APIUrl)
        var request = URLRequest(url: url!)
        
        request.setValue(xdate, forHTTPHeaderField: "x-date")
        request.setValue(authorization, forHTTPHeaderField: "Authorization")
        request.setValue("gzip", forHTTPHeaderField: "Accept-Encoding")
        
        return request
        
    }
    
   

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}




