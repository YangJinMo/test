//
//  QueryService.swift
//  iTunesExplorer
//
//  Created by YangJinMo on 2021/04/21.
//

import Foundation
import RxSwift

protocol QueryServiceProtocol {
  func getSearchResults(searchTerm: String) -> Observable<[Track]>
}

/// Runs query data task, and stores results in array of Tracks
class QueryService: QueryServiceProtocol {
  
  // MARK: - Constants
  
  let defaultSession = URLSession(configuration: .default)
  
  // MARK: - Variables And Properties
  
  var dataTask: URLSessionDataTask?
  var errorMessage = ""
  var tracks: [Track] = []
  
  // MARK: - Type Alias
  
  typealias JSONDictionary = [String: Any]
  typealias QueryResult = ([Track]?, String) -> Void
  
  // MARK: - Internal Methods
  
  func getSearchResults(searchTerm: String, completion: @escaping QueryResult) {
    
    dataTask?.cancel()
    
    if var urlComponents = URLComponents(string: "https://itunes.apple.com/search") {
      urlComponents.query = "media=music&entity=song&term=\(searchTerm)"
      
      guard let url = urlComponents.url else {
        return
      }
      
      dataTask = defaultSession.dataTask(with: url) { [weak self] data, response, error in
        defer {
          self?.dataTask = nil
        }
        
        if let error = error {
          self?.errorMessage += "DataTask error: " + error.localizedDescription + "\n"
        } else if
          let data = data,
          let response = response as? HTTPURLResponse, response.statusCode == 200 {
          
          self?.updateSearchResults(data)
          
          DispatchQueue.main.async {
            completion(self?.tracks, self?.errorMessage ?? "")
          }
        }
      }
      dataTask?.resume()
    }
  }
  
  func getSearchResults(searchTerm: String) -> Observable<[Track]> {
    
    return Observable.create { observer -> Disposable in
      
      self.dataTask?.cancel()
      
      guard var urlComponents = URLComponents(string: "https://itunes.apple.com/search") else {
        observer.onError(NSError(domain: "error: urlComponents", code: -1, userInfo: nil))
        return Disposables.create()
      }
      
      urlComponents.query = "media=music&entity=song&term=\(searchTerm)"
      
      guard let url = urlComponents.url else {
        observer.onError(NSError(domain: "error: \(urlComponents.string ?? "")", code: -1, userInfo: nil))
        return Disposables.create()
      }
      
      self.dataTask = self.defaultSession.dataTask(with: url) { [weak self] data, response, error in
        defer {
          self?.dataTask = nil
        }
        
        if let error = error {
          observer.onError(NSError(domain: "error: \(error.localizedDescription)", code: -1, userInfo: nil))
        } else {
          guard
            let data = data,
            let response = response as? HTTPURLResponse, response.statusCode == 200
          else {
            observer.onError(NSError(domain: "error: data", code: -1, userInfo: nil))
            return
          }
          
          var jsonDictionary: JSONDictionary?
          self?.tracks.removeAll()
          
          do {
            jsonDictionary = try JSONSerialization.jsonObject(with: data, options: []) as? JSONDictionary
          } catch let parseError as NSError {
            observer.onError(NSError(domain: "JSONSerialization error: \(parseError.localizedDescription)\n", code: -1, userInfo: nil))
            return
          }
          
          guard let results = jsonDictionary!["results"] as? [Any] else {
            observer.onError(NSError(domain: "Dictionary does not contain results key\n", code: -1, userInfo: nil))
            return
          }
          
          var index = 0
          
          for trackDictionary in results {
            guard let trackDictionary = trackDictionary as? JSONDictionary else {
              observer.onError(NSError(domain: "Problem parsing trackDictionary\n", code: -1, userInfo: nil))
              return
            }
            let track = Track(json: trackDictionary, index: index)
            self?.tracks.append(track)
            index += 1
            /*
            do {
              let track = try JSONDecoder().decode([Track].self, from: data)
              observer.onNext(self?.tracks ?? [])
            } catch {
              observer.onError(error)
            }
             */
          }
        }
      }
      
      self.dataTask?.resume()
      
      return Disposables.create {
        self.dataTask?.cancel()
      }
    }
  }
  
  // MARK: - Private Methods
  
  private func updateSearchResults(_ data: Data) {
    var response: JSONDictionary?
    tracks.removeAll()
    
    do {
      response = try JSONSerialization.jsonObject(with: data, options: []) as? JSONDictionary
    } catch let parseError as NSError {
      errorMessage += "JSONSerialization error: \(parseError.localizedDescription)\n"
      return
    }
    
    guard let results = response!["results"] as? [Any] else {
      errorMessage += "Dictionary does not contain results key\n"
      return
    }
    
    var index = 0
    
    for trackDictionary in results {
      guard let trackDictionary = trackDictionary as? JSONDictionary else {
        errorMessage += "Problem parsing trackDictionary\n"
        return
      }
      let track = Track(json: trackDictionary, index: index)
      tracks.append(track)
      index += 1
    }
  }
  
//  func parse(_ json: [String : Any]) -> [Track]? {
//    let results = json["results"] as? [[String: Any]]
//    return results?.compactMap(Track.init)
//  }
}

