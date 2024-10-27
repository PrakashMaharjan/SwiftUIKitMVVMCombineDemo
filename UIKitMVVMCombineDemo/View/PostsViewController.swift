//
//  PostsViewController.swift
//  UIKitMVVMCombineDemo
//
//  Created by PM on 25/10/2024.
//

import UIKit
import Combine

class PostsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    // table view setup
    private lazy var tableView: UITableView = {
        let tableVC = UITableView(frame: .zero)
        tableVC.translatesAutoresizingMaskIntoConstraints = false
        tableVC.isUserInteractionEnabled = true
        tableVC.clipsToBounds = true
        tableVC.isScrollEnabled = true
        tableVC.separatorStyle = .none
        tableVC.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 32, right: 0)
        tableVC.delegate = self
        tableVC.dataSource = self
        return tableVC
    }()
    
    private let viewModel = PostsViewViewModel()
    private var cancellables = Set<AnyCancellable>()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let loadMoreLoadingIndicator = UIActivityIndicatorView(style: .medium)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.title = "Posts"
        navigationController?.navigationBar.prefersLargeTitles = true
        setupTableView()
        setupLoadingIndicator()
        setupBindings()
        
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
            
        ])
        tableView.register(PostTableViewCell.self, forCellReuseIdentifier: PostTableViewCell.identifier)
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        
        // Set up loading indicator for pagination
        loadMoreLoadingIndicator.hidesWhenStopped = true
        tableView.tableFooterView = loadMoreLoadingIndicator
    }
    
    private func setupLoadingIndicator() {
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingIndicator)
        
        // Center the initial loading indicator in the view
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        loadingIndicator.startAnimating()
    }
    
    @objc private func handleRefresh() {
        viewModel.refresh()
    }
    
    private func setupBindings() {
        viewModel.$posts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)
        
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.loadingIndicator.startAnimating()
                    self?.tableView.isHidden = true // Hide table view until data is loaded
                } else {
                    self?.loadingIndicator.stopAnimating()
                    self?.tableView.isHidden = false
                    self?.tableView.refreshControl?.endRefreshing()
                }
            }
            .store(in: &cancellables)
        
        viewModel.$isLoadingMore
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoadingMore in
                if isLoadingMore {
                    self?.loadMoreLoadingIndicator.startAnimating()
                } else {
                    self?.loadMoreLoadingIndicator.stopAnimating()
                }
            }
            .store(in: &cancellables)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("posts count: \(viewModel.posts.count)")
        return viewModel.posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PostTableViewCell.identifier, for: indexPath) as? PostTableViewCell else {
            return UITableViewCell()
        }
        
        let post = viewModel.posts[indexPath.row]
        cell.configure(with: post)
        
        // Trigger pagination when reaching the last cell
        if indexPath.row == viewModel.posts.count - 1 && viewModel.posts.count > 0 {
            viewModel.loadPosts()
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("tapped: \(indexPath.row)")
    }
}
