import 'dart:async';

import 'package:faker/faker.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class NetworkData<T> {
  final T? data;
  final bool isFetching;
  final Object? error;

  NetworkData(this.data, this.isFetching, this.error);

  NetworkData startFetching() {
    return NetworkData(this.data, true, null);
  }

  NetworkData setData(T data) {
    return NetworkData(data, false, null);
  }

  NetworkData setError(Object error) {
    return NetworkData(this.data, false, error);
  }
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage('Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;

  MyHomePage(this.title) : super();

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class DataFetcherService {
  int _fetchCounter = 0;

  Future<String> fetchSomeText() {
    _fetchCounter++;
    if (_fetchCounter % 3 == 0) {
      return Future.delayed(Duration(seconds: 2)).then((_) => Future.error("Some Data Fetching Error"));
    } else {
      return Future.delayed(Duration(seconds: 2)).then((value) => faker.person.name());
    }
  }
}

class _MyHomePageState extends State<MyHomePage> {
  DataFetcherService _dataFetcher = DataFetcherService();
  StreamController<String> _incomingText$ = StreamController<String>();

  bool _isFetching = false;

  void _fetchText() {
    setState(() {
      _isFetching = true;
    });

    _dataFetcher.fetchSomeText().then((text) {
      _incomingText$.add(text);
    }).catchError((error) {
      _incomingText$.addError(error);
    }).whenComplete(() {
      setState(() {
        _isFetching = false;
      });
    });
  }

  @override
  void initState() {
    _fetchText();
    super.initState();
  }

  void dispose() {
    _incomingText$.close();
    super.dispose();
  }

  Widget _renderError(Object error) {
    return Text(
      'Error: ${error.toString()}',
      style: TextStyle(fontSize: 15, color: Colors.red),
    );
  }

  Widget _renderSpinner({required double size, required Color color}) {
    return SizedBox(
      child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(color)),
      width: size,
      height: size,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String>(
        stream: _incomingText$.stream,
        builder: (context, snapshot) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.title),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'Fetched Text below:',
                  ),
                  Text(
                    snapshot.data ?? "",
                    style: Theme.of(context).textTheme.headline4,
                  ),
                  if (snapshot.hasError) _renderError(snapshot.error!),
                  if (snapshot.connectionState == ConnectionState.waiting) _renderSpinner(size: 60, color: Colors.blue),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: _isFetching ? null : _fetchText,
              tooltip: 'Fetch more data',
              label: Text(snapshot.connectionState == ConnectionState.waiting ? "Waiting for data" : "Fetch more data"),
              icon: _isFetching && snapshot.connectionState != ConnectionState.waiting
                  ? _renderSpinner(size: 20, color: Colors.white)
                  : null,
            ), // This trailing comma makes auto-formatting nicer for build methods.
          );
        });
  }
}
