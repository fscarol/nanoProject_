//
//  ViewController.swift
//  Lab
//
//  Created by Roberto Evangelista da Silva Filho on 13/12/2018.
//  Copyright © 2018 Roberto Evangelista da Silva Filho. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var myTableView: UITableView!
    
    let searchController = UISearchController(searchResultsController: nil)
    let tableViewCcellIdentifier: String = "actorCell"
    let actorSegue: String = "selectActorSegue"
    let cellHeightSize: CGFloat = 120
    var apiQuery: String = ""
    var customFont: UIFont?
    let greeting = GreetingGenerator()
    
    var color1 = UIColor(displayP3Red: 200/255, green: 104/255, blue: 96/255, alpha: 1)
    var color2 = UIColor(displayP3Red: 40/255, green: 48/255, blue: 56/255, alpha: 1)

    let networkHelper = NetworkHelper()
  
    var searchActors = [Actor]()  {
        didSet {
            myTableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        myTableView.delegate = self
        myTableView.dataSource = self
        searchController.searchBar.delegate = self
        
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = greeting.getRandomGreeting()
        
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
        
        myTableView.tableHeaderView = searchController.searchBar
        
        customFont = UIFont(name: "Quicksand-Regular", size: UIFont.labelFontSize)
        
        viewPersonalization()
        
    }
    
    func searchActorRequest() {
        let searchRequest = "/search/person"
        let myQueryItems = [
            "api_key": networkHelper.apiKey,
            "query": apiQuery
        ]
        var urlComponents = URLComponents(string: networkHelper.apiURL + searchRequest)
        urlComponents?.queryItems = networkHelper.queryItems(dictionary: myQueryItems)
        print(urlComponents!)
        
        let task = URLSession.shared.dataTask(with: urlComponents!.url!) { (data, response, error) in
            guard let dataResponse = data,
                error == nil else {
                    print(error!.localizedDescription)
                    return
            }
            do {
                let decode = try JSONDecoder().decode(ActorSearchResponse.self, from: dataResponse)
                DispatchQueue.main.async {
                    guard let results = decode.results else {
                        return
                    }
                    
                    self.searchActors = results
                }
            } catch let parsinError {
                print(parsinError.localizedDescription)
            }
        }
        task.resume()
    }
    
    func viewPersonalization() {
        searchController.searchBar.barTintColor = color1
        UITextField.appearance(whenContainedInInstancesOf: [UISearchController.self]).defaultTextAttributes = [NSAttributedString.Key.font: self.customFont!]
        
        let cancelButtonAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        UIBarButtonItem.appearance().setTitleTextAttributes(cancelButtonAttributes , for: .normal)

    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchActors.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: tableViewCcellIdentifier, for: indexPath) as! ActorTableViewCell
        
        var imgBuilder = ImageBuilder()
        let actorProfilePath = searchActors[indexPath.row].picture
        
        resetCellProperties(for: cell)
        
        cell.actorName.text = searchActors[indexPath.row].name
        
        if imgBuilder.isImagePathValid(for: actorProfilePath) {
            imgBuilder.getImage(imgBuilder.path) { (imageData, error) -> (Void) in
                cell.actorPicture?.image = UIImage(data: imageData!)
            }
        } else {
            cell.actorPicture?.image = UIImage(named: imgBuilder.noImageAvaiable)
        }
        return cell
    }
    
    func resetCellProperties(for cell: ActorTableViewCell) {
        cell.actorName.text = nil
        cell.actorPicture.image = nil
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeightSize
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let actor = searchActors[indexPath.row]
        performSegue(withIdentifier: actorSegue, sender: actor)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? ActorDetailsViewController {
            controller.selectedActor = sender as? Actor
        }
    }
}

extension ViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchActors.removeAll()
        myTableView.reloadData()
        searchBar.resignFirstResponder()
        filterContentForSearchText(searchBar.text!)
    }
    
    func filterContentForSearchText(_ searchText: String) {
        apiQuery = searchText
        searchActorRequest()
    }

}
