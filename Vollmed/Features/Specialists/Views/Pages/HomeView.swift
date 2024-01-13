//
//  HomeView.swift
//  Vollmed
//
//  Created by Felipe Assis on 09/01/24.
//

import SwiftUI

struct HomeView: View {
    
    //MARK: Atributes
    let viewModel = HomeViewModel(service: HomeNetworkinService(), auth: AuthService())
    
    //MARK: States
    @State private var specialistsD: [Specialist] = []
    @State private var isShowingSnackBar: Bool = false
    @State private var isLoading: Bool = true
    @State private var errorMessage: String = ""
    
    var body: some View {
        
        ZStack {
            ScrollView(showsIndicators: false) {
                VStack {
                    Image(.logo)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200)
                        .padding(.vertical, 32)
                    Text("Boas-vindas!")
                        .font(.title2)
                        .bold()
                        .foregroundColor(Color(.lightBlue))
                    Text("Veja abaixo os especialistas da Vollmed disponíveis e marque já a sua consulta!")
                        .font(.title3)
                        .bold()
                        .foregroundColor(.accentColor)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 16)
                    
                    if isLoading {
                        SkeletonView()
                    } else {
                        ForEach(specialistsD) { specialist in
                            SpecialistCardView(specialist: specialist)
                                .padding(.bottom, 8)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.top)
            .onAppear {
                Task {
                    do {
                        guard let response = try await viewModel.getSpecialists() else { return }
                        specialistsD = response
                    } catch {
                        isShowingSnackBar = true
                        let errorType = error as? RequestError
                        errorMessage = errorType?.customMessage ?? "Ops! Ocorreu um erro"
                    }

                    isLoading = false
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        Task {
                            await viewModel.logout()
                        }
                    }, label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.forward")
                                .foregroundStyle(.accent)
                            Text("Logout")
                                .foregroundStyle(.accent)
                        }
                    })
                }
            }
        }
        
        if isShowingSnackBar {
            SnackBarView(message: errorMessage,isSuccess: nil, isShowing: $isShowingSnackBar)
        }
    }
}

#Preview {
    HomeView()
}
