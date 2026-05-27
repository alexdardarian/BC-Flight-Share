//
//  ContentView.swift
//  BC Flight Share
//
//  Created by Alex Dardarian on 5/27/26.
//

import SwiftUI

struct ContentView: View {
    @State private var authVM = AuthViewModel()

    var body: some View {
        Group {
            if authVM.isLoading {
                ProgressView()
                    .tint(Color.bcMaroon)
            } else if authVM.currentUser != nil {
                HomeView()
                    .environment(authVM)
            } else {
                AuthView()
                    .environment(authVM)
            }
        }
    }
}
