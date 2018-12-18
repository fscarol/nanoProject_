//
//  ActorDetailsViewController.swift
//  Lab
//
//  Created by Roberto Evangelista da Silva Filho on 14/12/2018.
//  Copyright © 2018 Roberto Evangelista da Silva Filho. All rights reserved.
//

import UIKit

class ActorDetailsViewController: UIViewController {
    
    @IBOutlet weak var myTableView: UITableView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var birthdayLabel: UILabel!
    @IBOutlet weak var birthplaceLabel: UILabel!
    @IBOutlet weak var biographyLabel: UITextView!
    @IBOutlet weak var profilePicture: UIImageView!
    
    let networkHelper = NetworkHelper()

    let movieCellIdentifier: String = "movieCell"
    
    var imgBuilder = ImageBuilder()
    
    var selectedActor: Actor?
    var fullActor: Actor? {
        didSet {
            nameLabel.text = fullActor?.name
            birthdayLabel.text = fullActor?.birthday
            birthplaceLabel.text = fullActor?.birthplace
            biographyLabel.text = fullActor?.biography
            
            if imgBuilder.isImagePathValid(for: fullActor?.picture) {
                imgBuilder.getImage(imgBuilder.path) { (imageData, error) -> (Void) in
                    self.profilePicture.image = UIImage(data: imageData!)
                }
            } else {
                self.profilePicture.image = UIImage(named: self.imgBuilder.noImageAvaiable)
            }
        }
    }
    
    var searchMovies: [Movie]? {
        didSet {
            searchMovieDetailRequest()
            self.myTableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        myTableView.dataSource = self
        myTableView.delegate = self
        searchActorDetailsRequest()
        searchMoviesRequest()
        searchMovieDetailRequest()
    }
    
    func searchActorDetailsRequest() {
        guard let actor = selectedActor else {
            print("Não recebi nenhum ator dessa segue")
            return
        }
        let searchRequest = "/person/\(actor.id)"
        let myQueryItems = [
            "api_key": networkHelper.apiKey
        ]
        var urlComponents = URLComponents(string: networkHelper.apiURL + searchRequest)
        urlComponents?.queryItems = networkHelper.queryItems(dictionary: myQueryItems)
        
        let task = URLSession.shared.dataTask(with: urlComponents!.url!) { (data, response, error) in
            guard let dataResponse = data, error == nil else {
                print(error!.localizedDescription)
                return
            }
            do {
                let decode = try JSONDecoder().decode(Actor.self, from: dataResponse)
                DispatchQueue.main.async {
                    self.fullActor = decode
                }
            } catch let parsinError{
                print(parsinError.localizedDescription)
            }
        }
        task.resume()
    }
    
    func searchMoviesRequest() {
        guard let actor = selectedActor else {
            print("Não recebi nenhum ator dessa segue")
            return
        }
        let searchRequest = "/person/\(actor.id)/movie_credits"
        let myQueryItems = [
            "api_key": networkHelper.apiKey
        ]
        var urlComponents = URLComponents(string: networkHelper.apiURL + searchRequest)
        urlComponents?.queryItems = networkHelper.queryItems(dictionary: myQueryItems)
        
        let task = URLSession.shared.dataTask(with: urlComponents!.url!) { (data, response, error) in
            guard let dataResponse = data, error == nil else {
                print(error!.localizedDescription)
                return
            }
            do {
                let decode = try JSONDecoder().decode(MovieSearchResponse.self, from: dataResponse)
                DispatchQueue.main.async {
                    self.searchMovies = decode.cast
                }
            } catch let parsinError{
                print(parsinError.localizedDescription)
            }
        }
        task.resume()
    }
    
    func searchMovieDetailRequest() {
        guard var movies = searchMovies else { return }
        for (index, movie) in movies.enumerated() {
            let searchRequest = "/movie/\(movie.id)"
            let myQueryItems = [
                "api_key": networkHelper.apiKey
            ]
            var urlComponents = URLComponents(string: networkHelper.apiURL + searchRequest)
            urlComponents?.queryItems = networkHelper.queryItems(dictionary: myQueryItems)
            
            let task = URLSession.shared.dataTask(with: urlComponents!.url!) { (data, response, error) in
                guard let dataResponse = data, error == nil else {
                    print(error!.localizedDescription)
                    return
                }
                do {
                    let decode = try JSONDecoder().decode(Movie.self, from: dataResponse)
                    DispatchQueue.main.async {
                        movies[index].buildMovie(for: decode)
                    }
                } catch let parsinError{
                    print(parsinError.localizedDescription)
                }
            }
            task.resume()
        }
    }
}

extension ActorDetailsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchMovies?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: movieCellIdentifier, for: indexPath) as! MovieTableViewCell
        
        resetCellProperties(for: cell)
        
        if let movies = searchMovies {
            cell.name.text = movies[indexPath.row].title
            cell.releaseDate.text = "Release date: \(movies[indexPath.row].releaseDate ?? "not avaialble")"
            cell.duration.text = "\(movies[indexPath.row].duration ?? 0)"
            
            if imgBuilder.isImagePathValid(for: movies[indexPath.row].poster) {
                imgBuilder.getImage(imgBuilder.path) { (imageData, error) -> (Void) in
                    cell.poster.image = UIImage(data: imageData!)
                }
            } else {
                cell.poster.image = UIImage(named: self.imgBuilder.noImageAvaiable)
            }
        }
        
        return cell
    }
    
    func resetCellProperties(for cell: MovieTableViewCell) {
        cell.genres.text = nil
        cell.poster.image = nil
        cell.name.text = nil
        cell.duration.text = nil
        cell.releaseDate.text = nil
    }
}
