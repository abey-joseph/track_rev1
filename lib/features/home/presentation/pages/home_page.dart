import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:track/core/extensions/context_extensions.dart';
import 'package:track/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:track/features/auth/presentation/bloc/auth_event.dart';

@RoutePage()
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed:
                () => context.read<AuthBloc>().add(
                  const AuthEvent.signOutRequested(),
                ),
          ),
        ],
      ),
      body: Center(
        child: Text(
          'Welcome to Track!',
          style: context.textTheme.headlineMedium,
        ),
      ),
    );
  }
}
