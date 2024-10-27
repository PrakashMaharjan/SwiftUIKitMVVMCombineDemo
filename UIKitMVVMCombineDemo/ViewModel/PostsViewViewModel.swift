//
//  PostsViewViewModel.swift
//  UIKitMVVMCombineDemo
//
//  Created by PM on 25/10/2024.
//

import Foundation
import Combine

class PostsViewViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var currentPage = 1
    private var canLoadMore = true
    private var cancellables = Set<AnyCancellable>()
    
    // Load initial data
    init() {
        loadPosts()
    }
    
    func loadPosts(isRefreshing: Bool = false) {
        guard !isLoading, canLoadMore || isRefreshing else { return }
        
        if isRefreshing {
            currentPage = 1
        } else {
            isLoadingMore = true // Trigger pagination loading indicator
        }
        isLoading = true
        
        NetworkService.shared.fetchPosts(page: currentPage, limit: 10)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                self?.isLoadingMore = false
                if case .failure = completion {
                    self?.canLoadMore = false
                }
            }, receiveValue: { [weak self] newPosts in
                if isRefreshing {
                    self?.posts = newPosts
                } else {
                    self?.posts += newPosts
                }
                
                self?.canLoadMore = !newPosts.isEmpty
                if !newPosts.isEmpty { self?.currentPage += 1 }
            })
            .store(in: &cancellables)
    }
    
    func refresh() {
        loadPosts(isRefreshing: true)
    }
}
